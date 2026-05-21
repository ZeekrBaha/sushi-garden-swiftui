// SushiGarden/Features/Promotions/View/PromotionsView.swift
import SwiftUI

struct PromotionsView: View {
    let deps: Dependencies
    @StateObject private var vm = PromotionsViewModel()

    init(deps: Dependencies) {
        self.deps = deps
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(vm.banners) { b in
                            Image(b.imageName)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.bannerCorner))
                                .accessibilityIdentifier("promo.\(b.id)")
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle(Strings.Tabs.promotions)
        }
        .tint(AppColor.accent)
    }
}
