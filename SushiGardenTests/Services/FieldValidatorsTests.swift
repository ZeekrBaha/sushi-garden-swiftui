import XCTest
@testable import SushiGarden

final class FieldValidatorsTests: XCTestCase {
    func test_email_valid() { XCTAssertTrue(FieldValidators.isValidEmail("a@b.ru")) }
    func test_email_invalid() {
        XCTAssertFalse(FieldValidators.isValidEmail("a@b"))
        XCTAssertFalse(FieldValidators.isValidEmail(""))
    }
    func test_password_minLength() {
        XCTAssertTrue(FieldValidators.isValidPassword("123456"))
        XCTAssertFalse(FieldValidators.isValidPassword("123"))
    }
    func test_phone_digitsCount() {
        XCTAssertTrue(FieldValidators.isValidPhone("+7 900 123 45 67"))
        XCTAssertFalse(FieldValidators.isValidPhone("123"))
    }
    func test_nonEmptyName() {
        XCTAssertTrue(FieldValidators.isNonEmpty(" Саша "))
        XCTAssertFalse(FieldValidators.isNonEmpty("   "))
    }
}
