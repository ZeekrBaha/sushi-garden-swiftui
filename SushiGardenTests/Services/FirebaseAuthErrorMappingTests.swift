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
}
