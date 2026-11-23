import SwiftUI

/// SwiftUI's `State` property wrapper.
///
/// In recent SDKs `@State` resolves to a macro whose plugin ships only with
/// Xcode. Using the wrapper type through an alias keeps the app buildable with
/// the Command Line Tools alone.
typealias ViewState<Value> = SwiftUI.State<Value>
