import SwiftUI

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(order.lines, id: \.self) { line in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.name)
                                    .font(AppFont.productTitle)
                                    .foregroundStyle(.white)
                                Text("× \(line.quantity)")
                                    .font(AppFont.weight)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer()
                            Text("\(line.priceRub * line.quantity) \(Strings.currency)")
                                .font(AppFont.weight)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.screenMargin)
                        .padding(.vertical, Spacing.sm)
                        .accessibilityIdentifier(A11y.Orders.detailLine(line.name))
                    }
                    Divider().overlay(AppColor.textSecondary.opacity(0.4))
                    HStack {
                        Text(Strings.Cart.total)
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(order.totalRub) \(Strings.currency)")
                            .font(AppFont.price)
                            .foregroundStyle(AppColor.accent)
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                    .padding(.vertical, Spacing.sm)
                }
                .accessibilityIdentifier(A11y.Orders.detailList)
            }
        }
        .navigationTitle(Strings.Orders.row(String(order.id.prefix(6))))
        .navigationBarTitleDisplayMode(.inline)
    }
}
