import SwiftUI

struct RegisterView: View {
    let deps: Dependencies
    let onAuthenticated: (UserProfile) -> Void

    var body: some View {
        AuthContainerView(
            vm: AuthViewModel(auth: deps.auth, mode: .register),
            onAuthenticated: onAuthenticated
        )
    }
}
