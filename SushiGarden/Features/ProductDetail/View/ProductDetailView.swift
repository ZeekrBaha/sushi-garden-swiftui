// SushiGarden/Features/ProductDetail/View/ProductDetailView.swift
import SwiftUI

struct ProductDetailView: View {
    @StateObject private var vm: ProductDetailViewModel
    init(product: Product, cart: CartService) {
        _vm = StateObject(wrappedValue: ProductDetailViewModel(product: product, cart: cart))
    }
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(vm.product.imageName).resizable().scaledToFit()
                    .frame(maxHeight: 280)
                Text(vm.product.name).font(AppFont.sen(22, bold: true)).foregroundStyle(.white)
                Text("\(vm.product.weightGrams) \(Strings.gram)")
                    .font(AppFont.weight).foregroundStyle(AppColor.textSecondary)
                Text(vm.product.description).font(AppFont.sen(14))
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.lg)
                stepper
                Button { vm.addToCart() } label: {
                    Text("\(Strings.Cart.checkout) · \(vm.product.priceRub * vm.quantity) \(Strings.currency)")
                        .font(AppFont.sectionHeader).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, Spacing.screenMargin)
                .accessibilityIdentifier(A11y.Detail.addToCart)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    private var stepper: some View {
        HStack(spacing: Spacing.lg) {
            Button { vm.decrement() } label: {
                Text("−").font(AppFont.mugesta(24))
            }
            .accessibilityIdentifier(A11y.Detail.stepperMinus)
            Text("\(vm.quantity)").font(AppFont.price).foregroundStyle(.white)
                .accessibilityIdentifier(A11y.Detail.quantity)
            Button { vm.increment() } label: {
                Text("+").font(AppFont.mugesta(24))
            }
            .accessibilityIdentifier(A11y.Detail.stepperPlus)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.sm)
        .background(AppColor.pricePill).clipShape(Capsule())
    }
}
