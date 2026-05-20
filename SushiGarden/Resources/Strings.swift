// SushiGarden/Resources/Strings.swift
enum Strings {
    enum Auth {
        static let register = "Регистрация"
        static let login = "Войти"
        static let name = "Имя"
        static let email = "Почта"
        static let password = "Пароль"
        static let consent = "Я согласен с Условиями предоставления услуг и Политикой конфиденциальности"
        static let haveAccount = "Уже есть аккаунт?"
        static let noAccount = "У вас нет аккаунта?"
    }
    enum Tabs {
        static let catalog = "Каталог"
        static let promotions = "Акции"
        static let orders = "Заказы"
        static let cart = "Корзина"
        static let profile = "Профиль"
    }
    enum Catalog {
        static let categories = ["Суши", "Роллы", "Горячие роллы", "Салаты", "WOK"]
        static let deliverTo = "Доставка по адресу:"
    }
    enum Cart {
        static let addMore = "Добавить еще"
        static let checkout = "Оформить заказ"
        static let confirm = "Подтвердить"
        static let sum = "Сумма заказа"
        static let delivery = "Доставка"
        static let serviceFee = "Сервисный сбор"
        static let total = "Итого"
        static let payOnline = "Картой онлайн"
    }
    enum Checkout {
        static let address = "Адрес"
        static let phone = "Телефон"
        static let delivery = "Доставка"
    }
    enum Profile {
        static let myOrders = "Мои заказы"
        static let cards = "Карты"
        static let logout = "Выйти"
    }
    static let currency = "₽"
    static let gram = "г"
}
