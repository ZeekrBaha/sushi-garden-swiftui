// SushiGarden/Features/Orders/View/OrdersView.swift
import SwiftUI

struct OrdersView: View {
    let deps: Dependencies
    @StateObject private var vm: OrdersViewModel

    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: OrdersViewModel(orders: deps.orders))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                if vm.isEmpty {
                    Text(Strings.Orders.empty)
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityIdentifier(A11y.Orders.empty)
                } else {
                    List(vm.orders) { o in
                        VStack(alignment: .leading) {
                            Text(Strings.Orders.row(String(o.id.prefix(6))))
                                .font(AppFont.productTitle)
                                .foregroundStyle(.white)
                            Text("\(o.totalRub) \(Strings.currency)")
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .listRowBackground(AppColor.tabBar)
                    }
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier(A11y.Orders.list)
                }
            }
            .navigationTitle(Strings.Tabs.orders)
            .onAppear { vm.load() }
        }
        .tint(AppColor.accent)
    }
}
