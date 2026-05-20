import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthService {
    var currentUser: UserProfile? {
        Auth.auth().currentUser.map { Self.profile(from: $0) }
    }

    func signUp(email: String, password: String, name: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            return UserProfile(id: result.user.uid, name: name, email: email)
        } catch { throw Self.map(error as NSError) }
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.profile(from: result.user)
        } catch { throw Self.map(error as NSError) }
    }

    func signOut() throws { try Auth.auth().signOut() }

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
