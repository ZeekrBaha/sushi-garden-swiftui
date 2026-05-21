import XCTest
import CoreLocation
@testable import SushiGarden

@MainActor
final class CourierSimulatorTests: XCTestCase {
    private let start = CLLocationCoordinate2D(latitude: 51.66, longitude: 39.20)
    private let end   = CLLocationCoordinate2D(latitude: 51.67, longitude: 39.18)

    func test_progressInterpolatesPosition() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 0)
        XCTAssertEqual(sim.position.latitude, start.latitude, accuracy: 0.0001)
        sim.update(progress: 1)
        XCTAssertEqual(sim.position.latitude, end.latitude, accuracy: 0.0001)
        sim.update(progress: 0.5)
        XCTAssertEqual(sim.position.latitude, (start.latitude + end.latitude)/2, accuracy: 0.0001)
    }
    func test_etaCountsDown() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 0.25)
        XCTAssertEqual(sim.remainingSeconds, 75)
    }
    func test_progressClamped() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 2.0)
        XCTAssertEqual(sim.position.latitude, end.latitude, accuracy: 0.0001)
        XCTAssertEqual(sim.remainingSeconds, 0)
    }
}
