import Foundation
import CoreLocation

@MainActor
final class TrackingViewModel: ObservableObject {
    let courier = Courier.demo
    let address = DeliveryAddress.demo
    let restaurant = CLLocationCoordinate2D(latitude: 51.6608, longitude: 39.2003)
    let destination = CLLocationCoordinate2D(latitude: 51.6720, longitude: 39.1843)
    let simulator: CourierSimulator

    init() {
        simulator = CourierSimulator(
            start: CLLocationCoordinate2D(latitude: 51.6608, longitude: 39.2003),
            destination: CLLocationCoordinate2D(latitude: 51.6720, longitude: 39.1843),
            etaSeconds: 25 * 60)
    }

    func begin() { simulator.startAnimation() }
    func end() { simulator.stopAnimation() }
    var etaText: String { "\(max(1, simulator.remainingSeconds / 60)) мин" }
}
