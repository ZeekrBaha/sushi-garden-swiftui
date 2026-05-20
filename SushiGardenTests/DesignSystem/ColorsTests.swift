import SwiftUI
import XCTest
@testable import SushiGarden

final class ColorsTests: XCTestCase {
    func test_accentRed_isDefined() {
        // Accent red #EC1A35 from Figma delivery pin / primary buttons
        let c = UIColor(AppColor.accent).cgColor.components ?? []
        XCTAssertEqual(c[0], 0.925, accuracy: 0.01)
        XCTAssertEqual(c[1], 0.102, accuracy: 0.01)
        XCTAssertEqual(c[2], 0.208, accuracy: 0.01)
    }
}
