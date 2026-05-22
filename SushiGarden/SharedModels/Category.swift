enum Category: String, CaseIterable, Identifiable {
    case sushi, rolls, hotRolls, salads, wok

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sushi: return "Суши"
        case .rolls: return "Роллы"
        case .hotRolls: return "Горячие роллы"
        case .salads: return "Салаты"
        case .wok: return "WOK"
        }
    }
}
