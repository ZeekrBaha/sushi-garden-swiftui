final class MenuRepository {
    let allProducts: [Product]
    let addOns: [AddOn]

    init() {
        let figma: [Product] = [
            Product(id: "hikari", name: "Хикари", category: .rolls, priceRub: 620,
                    weightGrams: 255, imageName: "product_hikari",
                    description: "Креветка в темпуре, сливочный сыр, огурец."),
            Product(id: "la", name: "Лос-Анджелес", category: .rolls, priceRub: 707,
                    weightGrams: 285, imageName: "product_la",
                    description: "Лосось, сливочный сыр, авокадо, икра тобико."),
            Product(id: "idaho", name: "Айдахо маки", category: .rolls, priceRub: 810,
                    weightGrams: 285, imageName: "product_idaho",
                    description: "Запечённый ролл с лососем и сыром."),
            Product(id: "osaka", name: "Осака маки", category: .rolls, priceRub: 740,
                    weightGrams: 275, imageName: "product_osaka",
                    description: "Угорь, огурец, унаги соус."),
        ]
        let extra: [Product] = [
            Product(id: "sushi_salmon", name: "Суши с лососем", category: .sushi, priceRub: 120,
                    weightGrams: 35, imageName: "product_la", description: "Лосось, рис."),
            Product(id: "sushi_eel", name: "Суши с угрём", category: .sushi, priceRub: 150,
                    weightGrams: 35, imageName: "product_osaka", description: "Угорь, рис."),
            Product(id: "hot_ebi", name: "Эби темпура", category: .hotRolls, priceRub: 690,
                    weightGrams: 260, imageName: "product_idaho", description: "Горячий ролл."),
            Product(id: "salad_chuka", name: "Чука салат", category: .salads, priceRub: 320,
                    weightGrams: 150, imageName: "product_hikari", description: "Водоросли чука."),
            Product(id: "wok_udon", name: "Удон с курицей", category: .wok, priceRub: 450,
                    weightGrams: 350, imageName: "product_idaho", description: "Удон, курица, овощи."),
        ]
        allProducts = figma + extra
        addOns = [
            AddOn(id: "wasabi", name: "Васаби", priceRub: 60),
            AddOn(id: "ginger", name: "Имбирь", priceRub: 60),
            AddOn(id: "soy", name: "Соевый соус", priceRub: 60),
        ]
    }

    func products(in category: Category) -> [Product] {
        allProducts.filter { $0.category == category }
    }
}
