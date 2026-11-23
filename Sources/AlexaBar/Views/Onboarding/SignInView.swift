import SwiftUI

struct SignInView: View {
    @EnvironmentObject var model: AppModel
    @ViewState private var email = ""
    @ViewState private var domain = AmazonRegion.guess.id
    @FocusState private var emailFocused: Bool

    private var valid: Bool {
        let e = email.trimmingCharacters(in: .whitespaces)
        return e.contains("@") && e.contains(".") && e.count > 4
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                AlexaGlyph(size: 54, glow: true)
                    .padding(.bottom, 4)
                Text("Alexa in your menu bar")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Sign in with the Amazon account that owns your Alexa devices.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("Amazon email", text: $email)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .textContentType(.username)
                        .focused($emailFocused)
                        .onSubmit(submit)
                }
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(0.06)))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(emailFocused ? Theme.alexaBlue.opacity(0.7) : Color.primary.opacity(0.08),
                                      lineWidth: emailFocused ? 1.5 : 1)
                )

                Menu {
                    ForEach(AmazonRegion.all) { r in
                        Button("\(r.flag)  \(r.name)  ·  \(r.id)") { domain = r.id }
                    }
                } label: {
                    let r = AmazonRegion.named(domain)
                    HStack(spacing: 8) {
                        Text(r.flag)
                        Text(r.name).font(.system(size: 13))
                        Text(r.id).font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
                    .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
            }

            Button(action: submit) {
                HStack(spacing: 6) {
                    Text("Continue with Amazon")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.brand))
                .shadow(color: Theme.alexaBlue.opacity(valid ? 0.4 : 0), radius: 8, y: 3)
                .opacity(valid ? 1 : 0.5)
            }
            .buttonStyle(PressableStyle())
            .disabled(!valid)
            .keyboardShortcut(.defaultAction)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                Text("You'll sign in on Amazon's own page in your browser. Alexa Bar never sees your password and only keeps the session tokens Amazon returns, stored on this Mac.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            if email.isEmpty { email = model.email }
            if !model.domain.isEmpty { domain = model.domain }
            emailFocused = email.isEmpty
        }
    }

    private func submit() {
        guard valid else { return }
        model.signIn(email: email, domain: domain)
    }
}
