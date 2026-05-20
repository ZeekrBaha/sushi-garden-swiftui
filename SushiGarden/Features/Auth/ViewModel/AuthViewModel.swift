import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode { case register, login }
    enum State: Equatable { case idle, loading, authenticated(UserProfile), error(String) }

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var consent = false
    @Published private(set) var state: State = .idle
    @Published var mode: Mode

    private let auth: AuthService
    init(auth: AuthService, mode: Mode) { self.auth = auth; self.mode = mode }

    var canSubmit: Bool {
        let base = FieldValidators.isValidEmail(email) && FieldValidators.isValidPassword(password)
        switch mode {
        case .login: return base
        case .register: return base && FieldValidators.isNonEmpty(name) && consent
        }
    }

    func toggleMode() { mode = (mode == .login) ? .register : .login; state = .idle }

    func submit() async {
        guard canSubmit else { return }
        state = .loading
        do {
            let user: UserProfile = (mode == .register)
                ? try await auth.signUp(email: email, password: password, name: name)
                : try await auth.signIn(email: email, password: password)
            state = .authenticated(user)
        } catch let e as AuthError {
            state = .error(Self.message(e))
        } catch {
            state = .error("Что-то пошло не так")
        }
    }

    private static func message(_ e: AuthError) -> String {
        switch e {
        case .invalidCredentials: return "Неверная почта или пароль"
        case .network: return "Нет соединения"
        case .unknown: return "Что-то пошло не так"
        }
    }
}
