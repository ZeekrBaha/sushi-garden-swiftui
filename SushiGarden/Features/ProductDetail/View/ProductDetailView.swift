// TEMP-STUB: replaced in Task 2.6
import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let cart: CartService

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack {
                Text(product.name).foregroundStyle(.white)
                Button("Add") { cart.add(product) }
                    .accessibilityIdentifier(A11y.Detail.addToCart)
            }
        }
    }
}
