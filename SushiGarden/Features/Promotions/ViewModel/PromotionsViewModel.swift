// SushiGarden/Features/Promotions/ViewModel/PromotionsViewModel.swift
import Foundation

struct Banner: Identifiable, Equatable {
    let id: String
    let imageName: String
}

@MainActor
final class PromotionsViewModel: ObservableObject {
    let banners: [Banner] = [
        Banner(id: "b1", imageName: "banner_promo_1"),
        Banner(id: "b2", imageName: "banner_promo_2")
    ]
}
