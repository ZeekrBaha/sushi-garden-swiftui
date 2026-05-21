// TEMP-STUB: replaced in Task 5.2
import SwiftUI

struct TrackingView: View {
    let deps: Dependencies

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Text("Отслеживание заказа").foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityIdentifier(A11y.Tracking.map)
    }
}
