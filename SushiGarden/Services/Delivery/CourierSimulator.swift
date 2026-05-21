import Foundation
import CoreLocation

@MainActor
final class CourierSimulator: ObservableObject {
    let start: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let etaSeconds: Int
    @Published private(set) var position: CLLocationCoordinate2D
    @Published private(set) var remainingSeconds: Int
    private var timer: Timer?
    private var elapsedSeconds: Double = 0

    init(start: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, etaSeconds: Int) {
        self.start = start
        self.destination = destination
        self.etaSeconds = etaSeconds
        self.position = start
        self.remainingSeconds = etaSeconds
    }

    func update(progress raw: Double) {
        let p = min(max(raw, 0), 1)
        position = CLLocationCoordinate2D(
            latitude: start.latitude + (destination.latitude - start.latitude) * p,
            longitude: start.longitude + (destination.longitude - start.longitude) * p)
        remainingSeconds = Int(Double(etaSeconds) * (1 - p))
    }

    /// Drives the live tracking animation. Not used in unit tests.
    func startAnimation(updateInterval: TimeInterval = 1) {
        elapsedSeconds = 0
        let total = Double(etaSeconds)
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] t in
            Task { @MainActor [weak self] in
                guard let self else { t.invalidate(); return }
                self.elapsedSeconds += updateInterval
                self.update(progress: self.elapsedSeconds / total)
                if self.elapsedSeconds >= total { t.invalidate() }
            }
        }
    }

    func stopAnimation() { timer?.invalidate(); timer = nil }
}
