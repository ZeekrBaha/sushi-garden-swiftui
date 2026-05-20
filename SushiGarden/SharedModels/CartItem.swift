struct CartItem: Identifiable, Equatable {
    let product: Product
    var quantity: Int

    var id: String { product.id }

    var lineTotal: Int { product.priceRub * quantity }
}
