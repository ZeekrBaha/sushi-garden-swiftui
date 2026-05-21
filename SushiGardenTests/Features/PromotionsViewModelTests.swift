// SushiGardenTests/Features/PromotionsViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class PromotionsViewModelTests: XCTestCase {
    func test_hasBanners() {
        let vm = PromotionsViewModel()
        XCTAssertGreaterThanOrEqual(vm.banners.count, 2)
        XCTAssertEqual(vm.banners.first?.imageName, "banner_promo_1")
    }
}
