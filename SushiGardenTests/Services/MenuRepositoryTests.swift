import XCTest
@testable import SushiGarden

final class MenuRepositoryTests: XCTestCase {
    func test_allCategoriesHaveItems() {
        let repo = MenuRepository()
        for c in Category.allCases {
            XCTAssertFalse(repo.products(in: c).isEmpty, "\(c.title) is empty")
        }
    }
    func test_knownFigmaItemExists() {
        let repo = MenuRepository()
        let hikari = repo.allProducts.first { $0.id == "hikari" }
        XCTAssertEqual(hikari?.priceRub, 620)
        XCTAssertEqual(hikari?.weightGrams, 255)
    }
    func test_addOnsPresent() {
        XCTAssertEqual(MenuRepository().addOns.count, 3)
        XCTAssertTrue(MenuRepository().addOns.allSatisfy { $0.priceRub == 60 })
    }
}
