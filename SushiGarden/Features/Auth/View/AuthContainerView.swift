import SwiftUI

struct AuthContainerView: View {
    @StateObject var vm: AuthViewModel
    var onAuthenticated: (UserProfile) -> Void

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Text(vm.mode == .register ? Strings.Auth.register : Strings.Auth.login)
                    .font(AppFont.sen(24, bold: true)).foregroundStyle(AppColor.textPrimary)
                if vm.mode == .register {
                    authField(Strings.Auth.name, text: $vm.name, id: A11y.Auth.nameField)
                }
                authField(Strings.Auth.email, text: $vm.email, id: A11y.Auth.emailField, keyboard: .emailAddress)
                secureField(Strings.Auth.password, text: $vm.password, id: A11y.Auth.passwordField)
                if vm.mode == .register {
                    HStack {
                        Text(Strings.Auth.consent)
                            .font(AppFont.sen(12)).foregroundStyle(AppColor.textSecondary)
                        Toggle("", isOn: $vm.consent)
                            .labelsHidden()
                            .accessibilityIdentifier(A11y.Auth.consentToggle)
                    }
                }
                Button(action: { Task { await vm.submit() } }) {
                    Text(vm.mode == .register ? Strings.Auth.register : Strings.Auth.login)
                        .font(AppFont.sectionHeader).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canSubmit)
                .accessibilityIdentifier(A11y.Auth.submit)

                Button(vm.mode == .register ? Strings.Auth.haveAccount : Strings.Auth.noAccount) {
                    vm.toggleMode()
                }
                .font(AppFont.sen(13)).foregroundStyle(AppColor.accent)
                .accessibilityIdentifier(A11y.Auth.toggleMode)

                if case let .error(msg) = vm.state {
                    Text(msg).font(AppFont.sen(12)).foregroundStyle(AppColor.accent)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .onChange(of: vm.state) { _, new in
            if case let .authenticated(user) = new { onAuthenticated(user) }
        }
    }

    private func authField(_ placeholder: String, text: Binding<String>, id: String,
                           keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard).autocorrectionDisabled().textInputAutocapitalization(.never)
            .padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }

    private func secureField(_ placeholder: String, text: Binding<String>, id: String) -> some View {
        SecureField(placeholder, text: text)
            .padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }
}
