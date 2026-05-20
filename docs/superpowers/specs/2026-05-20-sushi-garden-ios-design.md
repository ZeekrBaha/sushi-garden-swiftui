# Sushi Garden iOS — Design Spec

**Date:** 2026-05-20
**Status:** Approved (design); pending implementation plan
**Figma source:** https://www.figma.com/design/wOK1MMzuJZF3pIOZhGHpY9/Error-Nil.-Apps?node-id=1-6 (file key `wOK1MMzuJZF3pIOZhGHpY9`, canvas "App1")

## 1. Overview

Sushi Garden is a Russian-language sushi delivery iOS app rebuilt from the Figma
design. It is a SwiftUI app using MVVM and async/await. Firebase Authentication
backs registration and login; everything else (menu, cart, orders, promotions,
delivery map) runs on local mock data with images extracted from Figma as
placeholders.

### Stated requirements (from the user)
- SwiftUI, MVVM, async/await.
- Registration via Firebase (credentials supplied later).
- Images taken from Figma as placeholders.
- Map via MapKit ("kitmap").
- UI tests for every feature on every screen.

### Approved scoping decisions
- **Backend scope:** Firebase Auth only. Menu, cart, orders, promotions are local.
- **Map:** Simulated courier animation along a hardcoded route (no live backend).
- **UI-test auth:** Bypassed via a launch argument that injects a fake auth
  service + seeded session, so UI tests run offline and deterministically.
- **App shell:** AppDelegate + SceneDelegate hybrid (UIKit shell hosting SwiftUI),
  matching the existing FridgeChef convention; Firebase is configured in AppDelegate.
- **Language:** Russian, matching the design exactly. Strings centralized for testability.
- **Fonts:** Bundle Sen (Regular/Bold, fetched from Google Fonts) and Mugesta
  (user supplies the file). Stepper `+`/`−` falls back to SF Symbols until Mugesta lands.
- **Persistence:** Placed orders persisted with SwiftData (Профиль → Мои заказы
  survives relaunch); active cart is in-memory and clears on app kill.

### User-supplied dependencies (later)
- Firebase `GoogleService-Info.plist` (real credentials).
- Mugesta font file (`.ttf`/`.otf`).

## 2. Project setup
- **Location:** `~/Desktop/llm-ai-projects/sushi-garden-ios`
- **App name:** `SushiGarden` · **Bundle:** `com.baha.sushigarden`
- **iOS:** 17.0 · **Swift:** 5.10 · **Project generation:** XcodeGen (`project.yml`)
- **Targets:** `SushiGarden` (app), `SushiGardenTests` (unit), `SushiGardenUITests` (UI).
- **Dependencies:** Firebase iOS SDK via SPM, `FirebaseAuth` product only.
- **Code signing:** disabled for local/sim builds (as in FridgeChef).
- `GoogleService-Info.plist` is git-ignored and injected at build time; a checked-in
  placeholder/stub keeps the project generating before real creds arrive.

## 3. Architecture (SwiftUI + MVVM + async/await)

```
SushiGarden/
  App/
    AppDelegate.swift          Firebase configuration
    SceneDelegate.swift        Root routing (Auth gate vs tab bar)
    RootTabBarController.swift  5-tab UIKit shell hosting SwiftUI screens
    Dependencies.swift         DI container (service protocols)
    Info.plist · LaunchScreen.storyboard
  DesignSystem/
    Colors.swift · Typography.swift · Spacing.swift · Fonts/
  SharedModels/
    Product · Category · CartItem · AddOn · Order · OrderLine
    UserProfile · Courier · DeliveryAddress
  Services/
    Auth/      AuthService (protocol) · FirebaseAuthService · FakeAuthService
    Catalog/   MenuRepository (local mock + Figma images)
    Cart/      CartService (in-memory, observable)
    Orders/    OrderStore (SwiftData)
    Delivery/  CourierSimulator (animated route + ETA)
  Features/<Screen>/
    View/      SwiftUI views
    ViewModel/ @MainActor observable view models
```

**Conventions**
- ViewModels are `@MainActor`, observable, expose `async` methods, depend only on
  service **protocols** injected via `Dependencies`.
- ViewModels expose an `idle / loading / loaded / error` state enum (mirrors the
  existing `CatalogViewModel` pattern).
- Each screen is a self-contained Feature folder (View + ViewModel) testable in isolation.

## 4. Screens → ViewModels

| Area | Screens | Notes |
|------|---------|-------|
| Auth (pre-tab gate) | Регистрация (Register), Войти (Login) | Firebase-backed |
| Tab 1 — Каталог | Главная / Catalog | category tabs + product grid |
| Tab 2 — Акции | Promotions | banners + promo carousel |
| Tab 3 — Заказы | Orders list | reads SwiftData order history |
| Tab 4 — Корзина | Cart | line items + add-ons + total |
| Tab 5 — Профиль | Profile | user, order history, profile/cards rows, logout |
| Pushed/presented | ProductDetail, Адрес (Checkout), Order Tracking (map) | |

`SceneDelegate` chooses the root: no auth session → Auth flow; active session →
`RootTabBarController`.

## 5. Auth flow (Firebase)
`AuthService` protocol:
- `signUp(email:password:name:) async throws`
- `signIn(email:password:) async throws`
- `signOut() throws`
- `currentUser` / session change stream

Implementations:
- `FirebaseAuthService` — wraps FirebaseAuth with async/await.
- `FakeAuthService` — injected when `-UITEST` launch arg is present; deterministic,
  offline, pre-seedable with a signed-in user.

Validation: registration checks email format, password rules, non-empty name, and
the consent checkbox; login checks email/password. Show-password toggle per design.

## 6. Data & assets
- **Menu** is local mock data matching the Figma across 5 categories
  (Суши, Роллы, Горячие роллы, Салаты, WOK). Known items include:
  Хикари 620₽·255г, Лос-Анджелес 707₽·285г, Айдахо маки 810₽·285г,
  Осака маки 740₽·275г. Add-ons: Васаби, Имбирь, Соевый соус (60₽ each).
- **Figma images** extracted via the Figma REST API using the token from the MCP
  config: resolve `imageRef` fills via `/v1/files/{key}/images` (sushi photos) and
  render banner/logo/avatar nodes via `/v1/images/{key}?ids=...&format=png`. Saved
  into `Assets.xcassets` as placeholder imagesets.
- **Cart** in-memory (`CartService`). **Placed orders** persisted via SwiftData
  (`OrderStore`), surfaced in Профиль → Мои заказы and the Заказы tab.

## 7. Map (MapKit)
- SwiftUI `Map` (iOS 17 API) on the Order Tracking screen.
- `CourierSimulator` publishes coordinate updates along a hardcoded
  restaurant → delivery-address polyline; a courier annotation animates along it
  with an ETA countdown.
- Courier card (Максим Винокур, Курьер) with call buttons, per design.

## 8. Checkout
Адрес screen: delivery address, Кому / Телефон / Почта fields, payment method
(Картой онлайн), order summary (Сумма заказа, Доставка, Сервисный сбор, Итого),
and Подтвердить. Confirming creates an `Order` in SwiftData and navigates to Order
Tracking. Cart clears on successful order.

## 9. Testing strategy (TDD — failing test first)

**Unit tests (`SushiGardenTests`)**
- Every ViewModel against fake services (state transitions, error handling).
- `CartService`: line totals, quantity steppers, add-ons, grand total, clear.
- `CourierSimulator`: progress/ETA math.
- `MenuRepository`: categories and items.
- `OrderStore`: create/read/list against an in-memory SwiftData container.
- Form validators: email, password, phone.

**UI tests (`SushiGardenUITests`)**
- One XCUITest flow per screen, launched with `-UITEST` → `FakeAuthService` +
  seeded data, fully offline and deterministic.
- Coverage: register, login, catalog browse + category switch, product detail →
  add to cart, promotions, cart edit + add-ons, checkout submit, tracking screen
  appears, orders list, profile (incl. logout).
- Key interactive elements carry stable `accessibilityIdentifier`s.

## 10. Build phases (each phase TDD'd)
- **P0 — Scaffold:** XcodeGen project, design system (Colors/Typography/Spacing),
  font bundling, Figma asset extraction into `Assets.xcassets`.
- **P1 — Shell + Auth:** AppDelegate/SceneDelegate, RootTabBarController, DI,
  `AuthService` (Firebase + Fake), routing/auth gate, Register + Login screens.
- **P2 — Catalog:** MenuRepository mock data, Catalog screen (categories + grid),
  ProductDetail, CartService.
- **P3 — Cart + Checkout:** Cart screen (line items, add-ons, totals), Checkout,
  OrderStore (SwiftData) persistence.
- **P4 — Promotions + Profile + Orders:** Promotions screen, Profile, Orders list.
- **P5 — Tracking map:** MapKit tracking screen + CourierSimulator.
- **P6 — UI-test sweep + polish:** complete per-screen UI tests, visual polish.

## 11. Out of scope (v1)
- Real payment processing (UI only).
- Live courier tracking / real delivery backend.
- Push notifications.
- Firestore / remote menu or remote order storage.
- Localization beyond Russian.
