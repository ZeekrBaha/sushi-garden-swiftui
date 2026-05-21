// TEMP-STUB: replaced in Task 3.2
import SwiftUI

struct CartView: View {
    let deps: Dependencies

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Text(Strings.Tabs.cart).foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11y.Cart.list)
    }
}
