import SwiftUI

struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(product.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCorner))

            Text(product.name)
                .font(AppFont.productTitle)
                .foregroundStyle(AppColor.textPrimary)

            Text("\(product.weightGrams) \(Strings.gram)")
                .font(AppFont.weight)
                .foregroundStyle(AppColor.textSecondary)

            Text("\(product.priceRub) \(Strings.currency)")
                .font(AppFont.price)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.pricePill)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCorner))
        }
    }
}
