import Foundation

final class FakeAuthService: AuthService {
    private(set) var currentUser: UserProfile?
    private let shouldFail: Bool

    init(seeded: UserProfile? = nil, shouldFail: Bool = false) {
        self.currentUser = seeded
        self.shouldFail = shouldFail
    }

    func signUp(email: String, password: String, name: String) async throws -> UserProfile {
        if shouldFail { throw AuthError.unknown("forced") }
        let u = UserProfile(id: UUID().uuidString, name: name, email: email)
        currentUser = u
        return u
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        if shouldFail { throw AuthError.invalidCredentials }
        let u = UserProfile(id: "u1", name: "Александр Новиков", email: email)
        currentUser = u
        return u
    }

    func signOut() throws {
        currentUser = nil
    }
}
