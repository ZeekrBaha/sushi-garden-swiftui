import XCTest
@testable import SushiGarden

final class FirebaseAuthErrorMappingTests: XCTestCase {
    func test_mapsWrongPasswordToInvalidCredentials() {
        let ns = NSError(domain: "FIRAuthErrorDomain", code: 17009) // wrong password
        XCTAssertEqual(FirebaseAuthService.map(ns), .invalidCredentials)
    }
    func test_mapsNetworkError() {
        let ns = NSError(domain: "FIRAuthErrorDomain", code: 17020) // network
        XCTAssertEqual(FirebaseAuthService.map(ns), .network)
    }

    func test_signIn_throwsUnknown_whenFirebaseNotConfigured() async {
        let svc = FirebaseAuthService(isConfigured: { false })
        do {
            _ = try await svc.signIn(email: "a@b.ru", password: "123456")
            XCTFail("expected throw")
        } catch let e as AuthError {
            if case .unknown(let msg) = e {
                XCTAssertEqual(msg, "firebase-not-configured")
            } else {
                XCTFail("expected .unknown, got \(e)")
            }
        } catch {
            XCTFail("expected AuthError, got \(error)")
        }
    }

    func test_signUp_throwsUnknown_whenFirebaseNotConfigured() async {
        let svc = FirebaseAuthService(isConfigured: { false })
        do {
            _ = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Test")
            XCTFail("expected throw")
        } catch let e as AuthError {
            if case .unknown(let msg) = e {
                XCTAssertEqual(msg, "firebase-not-configured")
            } else {
                XCTFail("expected .unknown, got \(e)")
            }
        } catch {
            XCTFail("expected AuthError, got \(error)")
        }
    }

    func test_signOut_doesNotThrow_whenFirebaseNotConfigured() {
        let svc = FirebaseAuthService(isConfigured: { false })
        XCTAssertNoThrow(try svc.signOut())
    }

    func test_currentUser_isNil_whenFirebaseNotConfigured() {
        let svc = FirebaseAuthService(isConfigured: { false })
        XCTAssertNil(svc.currentUser)
    }
}
