import SwiftUI

struct CatalogView: View {
    let deps: Dependencies
    @StateObject private var vm: CatalogViewModel
    @State private var selected: Product?

    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: CatalogViewModel(menu: deps.menu, cart: deps.cart))
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                ScrollView {
                    categoryBar
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(vm.visibleProducts) { p in
                            Button { selected = p } label: { ProductCardView(product: p) }
                                .accessibilityIdentifier(A11y.Catalog.card(p.id))
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                    .accessibilityIdentifier(A11y.Catalog.grid)
                }
            }
            .navigationDestination(item: $selected) { p in
                ProductDetailView(product: p, cart: deps.cart)
            }
        }
        .tint(AppColor.accent)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(vm.categories) { c in
                    Button(c.title) { vm.select(c) }
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(c == vm.selectedCategory ? AppColor.textPrimary : AppColor.inactive)
                        .accessibilityIdentifier(A11y.Catalog.category(c.title))
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.sm)
        }
    }
}
