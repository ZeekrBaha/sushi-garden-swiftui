import Foundation
import FirebaseAuth
import FirebaseCore

final class FirebaseAuthService: AuthService {
    // FirebaseApp.configure() is skipped when GoogleService-Info.plist is absent
    // (e.g. UI smoke tests) — guard against the resulting crash. Injectable so
    // tests can exercise the "not configured" path deterministically instead
    // of depending on whether a real plist happens to sit in the working tree.
    private let isConfigured: () -> Bool

    init(isConfigured: @escaping () -> Bool = { FirebaseApp.app() != nil }) {
        self.isConfigured = isConfigured
    }

    var currentUser: UserProfile? {
        guard isConfigured() else { return nil }
        return Auth.auth().currentUser.map { Self.profile(from: $0) }
    }

    func signUp(email: String, password: String, name: String) async throws -> UserProfile {
        guard isConfigured() else { throw AuthError.unknown("firebase-not-configured") }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            return UserProfile(id: result.user.uid, name: name, email: email)
        } catch { throw Self.map(error as NSError) }
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        guard isConfigured() else { throw AuthError.unknown("firebase-not-configured") }
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.profile(from: result.user)
        } catch { throw Self.map(error as NSError) }
    }

    func signOut() throws {
        guard isConfigured() else { return }
        try Auth.auth().signOut()
    }

    static func profile(from u: User) -> UserProfile {
        UserProfile(id: u.uid, name: u.displayName ?? "", email: u.email ?? "")
    }

    static func map(_ e: NSError) -> AuthError {
        switch e.code {
        case 17009, 17011, 17004: return .invalidCredentials
        case 17020: return .network
        default: return .unknown("\(e.code)")
        }
    }
}
