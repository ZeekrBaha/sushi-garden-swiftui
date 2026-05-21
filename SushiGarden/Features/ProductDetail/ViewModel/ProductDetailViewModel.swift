// SushiGarden/Features/ProductDetail/ViewModel/ProductDetailViewModel.swift
import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let product: Product
    @Published private(set) var quantity = 1
    private let cart: CartService
    init(product: Product, cart: CartService) { self.product = product; self.cart = cart }
    func increment() { quantity += 1 }
    func decrement() { if quantity > 1 { quantity -= 1 } }
    func addToCart() { for _ in 0..<quantity { cart.add(product) } }
}
