import SwiftUI

struct AuthContainerView: View {
    @StateObject var vm: AuthViewModel
    var onAuthenticated: (UserProfile) -> Void
    @State private var showsPassword = false
    @State private var stableViewportHeight: CGFloat?

    var body: some View {
        GeometryReader { proxy in
            let height = stableViewportHeight ?? proxy.size.height

            ZStack(alignment: .bottom) {
                AppColor.background.ignoresSafeArea()

                VStack {
                    Text(vm.mode == .register ? Strings.Auth.register : Strings.Auth.login)
                        .font(AppFont.sen(29, bold: true))
                        .foregroundStyle(.white)
                        .padding(.top, titleTopPadding(for: height))
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 18) {
                    if vm.mode == .register {
                        authField(
                            label: Strings.Auth.name,
                            placeholder: "Александр",
                            text: $vm.name,
                            id: A11y.Auth.nameField
                        )
                    }
                    authField(
                        label: Strings.Auth.email,
                        placeholder: "example@gmail.com",
                        text: $vm.email,
                        id: A11y.Auth.emailField,
                        keyboard: .emailAddress
                    )
                    passwordField

                    if vm.mode == .register {
                        ZStack(alignment: .topLeading) {
                            HStack(alignment: .top, spacing: 14) {
                                checkbox

                                Text(Strings.Auth.consent)
                                    .font(AppFont.sen(12))
                                    .lineSpacing(1)
                                    .foregroundStyle(AuthPalette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityHidden(true)
                            .contentShape(Rectangle())
                            .onTapGesture { vm.consent.toggle() }

                            Toggle("", isOn: $vm.consent)
                                .labelsHidden()
                                .opacity(0.01)
                                .frame(width: 44, height: 28, alignment: .leading)
                                .accessibilityIdentifier(A11y.Auth.consentToggle)
                        }
                    }

                    Spacer(minLength: vm.mode == .login ? 48 : 0)

                    Button(action: {
                        Task {
                            if let user = await vm.submit() {
                                onAuthenticated(user)
                            }
                        }
                    }) {
                        ZStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text((vm.mode == .login ? Strings.Auth.login : Strings.Auth.register).uppercased())
                                    .font(AppFont.sen(15, bold: true))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!vm.canSubmit)
                    .opacity(vm.canSubmit ? 1 : 0.95)
                    .accessibilityIdentifier(A11y.Auth.submit)

                    HStack(spacing: 8) {
                        Spacer()
                        Text(vm.mode == .register ? Strings.Auth.haveAccount : Strings.Auth.noAccount)
                            .font(AppFont.sen(14))
                            .foregroundStyle(AuthPalette.secondaryAction)
                        Button(vm.mode == .register ? Strings.Auth.login.uppercased() : Strings.Auth.register.uppercased()) {
                            vm.toggleMode()
                        }
                        .font(AppFont.sen(14, bold: true))
                        .foregroundStyle(AppColor.accent)
                        .accessibilityIdentifier(A11y.Auth.toggleMode)
                        Spacer()
                    }
                    .padding(.top, 6)

                    if case let .error(msg) = vm.state {
                        Text(msg)
                            .font(AppFont.sen(12))
                            .foregroundStyle(AppColor.accent)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                }
                .padding(.horizontal, 22)
                .padding(.top, 38)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity)
                .frame(height: sheetHeight(for: height), alignment: .top)
                .background(.white)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                stableViewportHeight = max(stableViewportHeight ?? 0, proxy.size.height)
            }
            .onChange(of: proxy.size.height) { _, newHeight in
                stableViewportHeight = max(stableViewportHeight ?? 0, newHeight)
            }
        }
    }

    private func titleTopPadding(for height: CGFloat) -> CGFloat {
        min(max(height * 0.12, 72), 112)
    }

    private func sheetHeight(for height: CGFloat) -> CGFloat {
        let topOffset = min(max(height * 0.22, 148), 184)
        return max(0, height - topOffset)
    }

    private func authField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        id: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(AuthPalette.placeholder))
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(AppFont.sen(13))
                .foregroundStyle(AuthPalette.fieldText)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(AuthPalette.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier(id)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(Strings.Auth.password)
            HStack(spacing: 8) {
                if showsPassword {
                    TextField("", text: $vm.password, prompt: Text("**********").foregroundColor(AuthPalette.placeholder))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(AppFont.sen(13))
                        .foregroundStyle(AuthPalette.fieldText)
                        .accessibilityIdentifier(A11y.Auth.passwordField)
                } else {
                    SecurePasswordTextField(
                        text: $vm.password,
                        placeholder: "**********",
                        accessibilityIdentifier: A11y.Auth.passwordField
                    )
                }

                Button {
                    showsPassword.toggle()
                } label: {
                    Image(systemName: showsPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AuthPalette.icon)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(A11y.Auth.passwordVisibility)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(AuthPalette.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(AuthPalette.checkboxBorder, lineWidth: 1.4)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(vm.consent ? AppColor.accent : .clear)
            )
            .overlay {
                if vm.consent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 18, height: 18)
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label.uppercased())
            .font(AppFont.sen(12))
            .foregroundStyle(AuthPalette.label)
    }
}

private struct SecurePasswordTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let accessibilityIdentifier: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textContentType = .password
        textField.font = UIFont(name: "Sen-Regular", size: 13) ?? .systemFont(ofSize: 13)
        textField.textColor = UIColor(red: 0.18, green: 0.20, blue: 0.26, alpha: 1)
        textField.tintColor = UIColor(red: 0.80, green: 0.07, blue: 0.18, alpha: 1)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(red: 0.62, green: 0.66, blue: 0.75, alpha: 1)]
        )
        textField.accessibilityIdentifier = accessibilityIdentifier
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func editingChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }
    }
}

private enum AuthPalette {
    static let fieldBackground = Color(red: 0.942, green: 0.961, blue: 0.984)
    static let label = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let fieldText = Color(red: 0.18, green: 0.20, blue: 0.26)
    static let placeholder = Color(red: 0.62, green: 0.66, blue: 0.75)
    static let icon = Color(red: 0.66, green: 0.70, blue: 0.78)
    static let secondaryText = Color(red: 0.55, green: 0.58, blue: 0.68)
    static let secondaryAction = Color(red: 0.38, green: 0.40, blue: 0.50)
    static let checkboxBorder = Color(red: 0.82, green: 0.88, blue: 0.94)
}
