import AppKit
import SwiftUI

extension AppModel {
    func signIn(email: String, domain: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email
        self.domain = domain
        phase = .signingIn(url: nil)
        Task {
            do {
                let acct: AccountReply = try await backend.call("sign_in", ["email": email, "domain": domain])
                self.email = acct.email
                self.domain = acct.domain
                phase = .connecting
                try await loadEverything()
                becameReady()
                showToast("Signed in as \(acct.email)", .success)
            } catch let e as BackendError where e.isCancelled {
                phase = .signedOut
            } catch {
                phase = .signedOut
                showToast(error.localizedDescription, .error)
            }
        }
    }

    func cancelSignIn() {
        Task { _ = try? await backend.call("cancel_sign_in", as: EmptyReply.self) }
        phase = .signedOut
    }

    func signOut() {
        Task {
            _ = try? await backend.call("sign_out", as: EmptyReply.self)
            devices = []
            speakers = []
            states = [:]
            volumes = [:]
            lastUpdated = nil
            page = .home
            phase = .signedOut
        }
    }

    func handle(event: [String: Any]) {
        guard event["event"] as? String == "login_url",
              let s = event["url"] as? String, let url = URL(string: s),
              url.host == "127.0.0.1"  // only ever open our own local sign-in proxy
        else { return }
        phase = .signingIn(url: url)
        NSWorkspace.shared.open(url)
    }
}
