import XCTest
@testable import SushiGarden

@MainActor
final class TrackingViewModelTests: XCTestCase {
    func test_exposesCourierAndAddress() {
        let vm = TrackingViewModel()
        XCTAssertEqual(vm.courier.name, "Максим Винокур")
        XCTAssertEqual(vm.address.title, "Воронеж, Мира 36")
        XCTAssertGreaterThan(vm.simulator.remainingSeconds, 0)
    }
    func test_etaTextFormat() {
        let vm = TrackingViewModel()
        vm.simulator.update(progress: 0) // full eta
        XCTAssertTrue(vm.etaText.contains("мин"))
    }
}
