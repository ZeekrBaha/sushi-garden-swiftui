import SwiftUI

struct CartView: View {
    let deps: Dependencies
    @StateObject private var vm: CartViewModel
    @State private var goCheckout = false

    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: CartViewModel(cart: deps.cart, menu: deps.menu))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            ForEach(vm.items) { item in row(item) }
                            addOnsSection
                        }
                        .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(A11y.Cart.list)
                    }
                    checkoutBar
                }
            }
            .navigationTitle(Strings.Tabs.cart)
            .navigationDestination(isPresented: $goCheckout) {
                CheckoutView(deps: deps, total: vm.grandTotal)
            }
        }
        .tint(AppColor.accent)
    }

    private func row(_ item: CartItem) -> some View {
        HStack {
            Image(item.product.imageName).resizable().scaledToFill()
                .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(item.product.name).font(AppFont.productTitle).foregroundStyle(.white)
                Text("\(item.lineTotal) \(Strings.currency)").font(AppFont.weight)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.md) {
                Button("−") { vm.decrement(item) }.font(AppFont.mugesta(20))
                Text("\(item.quantity)").foregroundStyle(.white)
                Button("+") { vm.increment(item) }.font(AppFont.mugesta(20))
            }.foregroundStyle(.white)
        }
    }

    private var addOnsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.Cart.addMore).font(AppFont.sectionHeader).foregroundStyle(.white)
            ForEach(vm.addOns) { a in
                Button { vm.toggle(a) } label: {
                    HStack {
                        Image(systemName: vm.isSelected(a) ? "checkmark.circle.fill" : "circle")
                        Text(a.name).foregroundStyle(.white)
                        Spacer()
                        Text("\(a.priceRub) \(Strings.currency)").foregroundStyle(AppColor.textSecondary)
                    }
                }
                .tint(AppColor.accent)
                .accessibilityIdentifier(A11y.Cart.addon(a.id))
            }
        }
    }

    private var checkoutBar: some View {
        Button { goCheckout = true } label: {
            Text("\(Strings.Cart.checkout) · \(vm.grandTotal) \(Strings.currency)")
                .font(AppFont.sectionHeader).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding()
                .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(vm.isEmpty)
        .padding(Spacing.screenMargin)
        .accessibilityIdentifier(A11y.Cart.checkout)
    }
}
