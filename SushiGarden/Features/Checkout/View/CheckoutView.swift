// TEMP-STUB: replaced in Task 3.4
import SwiftUI

struct CheckoutView: View {
    let deps: Dependencies
    let total: Int

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Text(Strings.Cart.confirm).foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityIdentifier(A11y.Checkout.confirm)
    }
}
