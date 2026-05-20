import Foundation

enum FieldValidators {
    static func isValidEmail(_ s: String) -> Bool {
        let re = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return s.range(of: re, options: .regularExpression) != nil
    }

    static func isValidPassword(_ s: String) -> Bool {
        s.count >= 6
    }

    static func isValidPhone(_ s: String) -> Bool {
        s.filter(\.isNumber).count >= 10
    }

    static func isNonEmpty(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
