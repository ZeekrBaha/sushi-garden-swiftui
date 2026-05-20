// SushiGardenTests/DesignSystem/FontLoaderTests.swift
import UIKit
import XCTest
@testable import SushiGarden

final class FontLoaderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Explicitly register fonts in case the test host app hasn't launched AppDelegate.
        FontLoader.registerAll()
    }

    func test_senRegular_isAvailable() {
        XCTAssertNotNil(UIFont(name: "Sen-Regular", size: 16))
    }

    func test_senBold_isAvailable() {
        XCTAssertNotNil(UIFont(name: "Sen-Bold", size: 16))
    }

    func test_senFamily_isRegistered() {
        XCTAssertTrue(UIFont.familyNames.contains("Sen"), "Sen font family not registered")
    }
}
