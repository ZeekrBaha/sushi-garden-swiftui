struct Product: Identifiable, Equatable {
    let id: String
    let name: String
    let category: Category
    let priceRub: Int
    let weightGrams: Int
    let imageName: String
    let description: String
}
