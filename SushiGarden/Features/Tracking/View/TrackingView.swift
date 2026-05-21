import SwiftUI
import MapKit

struct TrackingView: View {
    let deps: Dependencies
    @StateObject private var vm = TrackingViewModel()
    @State private var camera: MapCameraPosition = .automatic

    init(deps: Dependencies) { self.deps = deps }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                Marker("Ресторан", coordinate: vm.restaurant).tint(.gray)
                Marker(vm.address.title, coordinate: vm.destination).tint(AppColor.accent)
                Annotation("Курьер", coordinate: vm.simulator.position) {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.title).foregroundStyle(AppColor.accent)
                }
                MapPolyline(coordinates: [vm.restaurant, vm.simulator.position])
                    .stroke(AppColor.accent, lineWidth: 3)
            }
            .accessibilityIdentifier(A11y.Tracking.map)
            .ignoresSafeArea(edges: .top)

            courierCard
        }
        .navigationTitle("Доставка")
        .onAppear {
            camera = .region(MKCoordinateRegion(
                center: vm.restaurant,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            vm.begin()
        }
        .onDisappear { vm.end() }
    }

    private var courierCard: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill").resizable().frame(width: 44, height: 44)
                .foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading) {
                Text(vm.courier.name).font(AppFont.productTitle).foregroundStyle(.white)
                Text(vm.courier.role).font(AppFont.weight).foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text(vm.etaText).font(AppFont.price).foregroundStyle(AppColor.accent)
        }
        .padding().background(AppColor.tabBar)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(Spacing.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11y.Tracking.courier)
    }
}
