import Foundation

enum AuthError: Error, Equatable {
    case invalidCredentials
    case network
    case unknown(String)
}

protocol AuthService: AnyObject {
    var currentUser: UserProfile? { get }
    func signUp(email: String, password: String, name: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() throws
}
