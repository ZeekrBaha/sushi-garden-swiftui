# Sushi Garden iOS — Quality & Feature Improvements

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the consent gate in registration, harden Firebase guards, add loading spinners, expand UI test coverage with stricter assertions, and add an order detail view with profile phone editing.

**Architecture:** Changes span four layers — ViewModel logic (consent gate, `isLoading`), service layer (Firebase guard), SwiftUI views (spinners, new `OrderDetailView`, profile phone field), and XCUITest (stricter assertions, new scenarios). Every task is independently committable and leaves the app in a working state.

**Tech Stack:** Swift 5.10, SwiftUI (iOS 17), XCTest + XCUITest, `@MainActor ObservableObject`, Firebase iOS SDK (SPM), SwiftData, UserDefaults.

---

## File Structure

**Files to create:**
- `SushiGarden/Features/Orders/View/OrderDetailView.swift` — new view: order lines, quantity, totals

**Files to modify:**
- `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift` — consent in `canSubmit`, add `isLoading`
- `SushiGarden/Features/Auth/View/AuthContainerView.swift` — spinner + auto-disable during loading
- `SushiGarden/Features/Checkout/View/CheckoutView.swift` — full-screen loading overlay
- `SushiGarden/Features/Orders/View/OrdersView.swift` — NavigationLink to detail
- `SushiGarden/Features/Profile/View/ProfileView.swift` — editable phone field (UserDefaults)
- `SushiGarden/Services/Auth/FirebaseAuthService.swift` — guard `FirebaseApp.app() != nil` in signUp/signIn/signOut
- `SushiGarden/Services/Cart/CartView.swift` — A11y identifiers on increment/decrement/qty
- `SushiGarden/App/Dependencies.swift` — `-UITEST_AUTH_FAIL` launch flag
- `SushiGarden/Resources/A11y.swift` — Cart qty/stepper identifiers, Orders detail identifiers, Profile phone
- `SushiGarden/Resources/Strings.swift` — no changes needed

**Test files to modify:**
- `SushiGardenTests/Features/AuthViewModelTests.swift` — consent tests + fix existing consent-unaware test
- `SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift` — Firebase guard unit tests
- `SushiGardenUITests/CheckoutUITests.swift` — tap confirm, verify tracking view appears
- `SushiGardenUITests/OrdersUITests.swift` — assert actual order row text; add detail drill-down test
- `SushiGardenUITests/AuthFlowUITests.swift` — auth failure error message, logout returns to auth
- `SushiGardenUITests/CartUITests.swift` — empty cart disabled, qty stepper, addon total change

---

## Task 1: Consent gate in `canSubmit`

The consent checkbox exists in `AuthContainerView` and `AuthViewModel.consent` is toggled, but
`canSubmit` for `.register` mode never checks it. A user can register without accepting terms.

**Files:**
- Modify: `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift:18-23`
- Modify: `SushiGardenTests/Features/AuthViewModelTests.swift`

- [ ] **Step 1: Write two failing unit tests**

In `SushiGardenTests/Features/AuthViewModelTests.swift`, add after the existing tests:

```swift
func test_register_disabled_whenConsentFalse() {
    let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
    vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
    // consent defaults to false — canSubmit must be false
    XCTAssertFalse(vm.canSubmit)
}

func test_register_enabled_whenConsentTrue() {
    let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
    vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
    vm.consent = true
    XCTAssertTrue(vm.canSubmit)
}
```

- [ ] **Step 2: Run unit tests, confirm the two new tests fail**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenTests/Features/AuthViewModelTests \
  2>&1 | grep -E "(PASS|FAIL|error)"
```

Expected: `test_register_disabled_whenConsentFalse` → **FAIL** (currently canSubmit ignores consent).
`test_register_enabled_whenConsentTrue` → PASS (already works by coincidence).
`test_registerEnabled_whenFieldsAreValid` → PASS (will break in next step).

- [ ] **Step 3: Fix `canSubmit` to require consent on register**

In `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift`, change lines 18–23:

```swift
// BEFORE:
var canSubmit: Bool {
    let base = FieldValidators.isValidEmail(email) && FieldValidators.isValidPassword(password)
    switch mode {
    case .login: return base
    case .register: return base && FieldValidators.isNonEmpty(name)
    }
}

// AFTER:
var canSubmit: Bool {
    let base = FieldValidators.isValidEmail(email) && FieldValidators.isValidPassword(password)
    switch mode {
    case .login: return base
    case .register: return base && FieldValidators.isNonEmpty(name) && consent
    }
}
```

- [ ] **Step 4: Fix the now-broken existing test**

The test `test_registerEnabled_whenFieldsAreValid` passes valid fields but not consent, so it now
**fails**. Add `vm.consent = true` to it:

```swift
func test_registerEnabled_whenFieldsAreValid() {
    let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
    vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
    vm.consent = true   // ← add this line
    XCTAssertTrue(vm.canSubmit)
}
```

- [ ] **Step 5: Run all unit tests, confirm all pass**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenTests/Features/AuthViewModelTests \
  2>&1 | grep -E "(PASS|FAIL|error)"
```

Expected: all 6 tests → **PASS**.

- [ ] **Step 6: Commit**

```bash
git add SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift \
        SushiGardenTests/Features/AuthViewModelTests.swift
git commit -m "fix: require consent checkbox before registration can submit"
```

---

## Task 2: Harden FirebaseAuthService against unconfigured Firebase

`FirebaseAuthService.currentUser` already guards `FirebaseApp.app() != nil`, but `signUp`, `signIn`,
and `signOut` call `Auth.auth()` directly. If Firebase is not configured (no `GoogleService-Info.plist`,
test environment, etc.) these calls crash the process rather than throwing a clean error.

**Files:**
- Modify: `SushiGarden/Services/Auth/FirebaseAuthService.swift:13-43`
- Modify: `SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift`

- [ ] **Step 1: Write unit tests for the guard**

In unit tests `FirebaseApp.app()` returns `nil` (Firebase is never configured in the test host).
Before the guard these tests crash the entire process. After the guard they throw `.unknown`.

Add to `SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift`:

```swift
func test_signIn_throwsUnknown_whenFirebaseNotConfigured() async {
    let svc = FirebaseAuthService()
    do {
        _ = try await svc.signIn(email: "a@b.ru", password: "123456")
        XCTFail("expected throw")
    } catch let e as AuthError {
        if case .unknown = e { /* expected */ } else { XCTFail("expected .unknown, got \(e)") }
    } catch {
        XCTFail("expected AuthError, got \(error)")
    }
}

func test_signUp_throwsUnknown_whenFirebaseNotConfigured() async {
    let svc = FirebaseAuthService()
    do {
        _ = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Test")
        XCTFail("expected throw")
    } catch let e as AuthError {
        if case .unknown = e { /* expected */ } else { XCTFail("expected .unknown, got \(e)") }
    } catch {
        XCTFail("expected AuthError, got \(error)")
    }
}
```

- [ ] **Step 2: Run to verify the red state**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenTests/Services/FirebaseAuthErrorMappingTests \
  2>&1 | grep -E "(PASS|FAIL|error|crash)"
```

Expected: test process **crashes** (not a graceful FAIL) — `Auth.auth()` force-unwraps
`FirebaseApp.defaultApp()` which is nil. This is the broken state we are fixing.

- [ ] **Step 3: Add the guards**

Replace the three method bodies in `SushiGarden/Services/Auth/FirebaseAuthService.swift`:

```swift
func signUp(email: String, password: String, name: String) async throws -> UserProfile {
    guard FirebaseApp.app() != nil else { throw AuthError.unknown("firebase-not-configured") }
    do {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = name
        try await change.commitChanges()
        return UserProfile(id: result.user.uid, name: name, email: email)
    } catch { throw Self.map(error as NSError) }
}

func signIn(email: String, password: String) async throws -> UserProfile {
    guard FirebaseApp.app() != nil else { throw AuthError.unknown("firebase-not-configured") }
    do {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return Self.profile(from: result.user)
    } catch { throw Self.map(error as NSError) }
}

func signOut() throws {
    guard FirebaseApp.app() != nil else { return }
    try Auth.auth().signOut()
}
```

- [ ] **Step 4: Run tests, confirm all pass**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenTests/Services/FirebaseAuthErrorMappingTests \
  2>&1 | grep -E "(PASS|FAIL|error)"
```

Expected: all 4 tests → **PASS** (2 existing + 2 new).

- [ ] **Step 5: Commit**

```bash
git add SushiGarden/Services/Auth/FirebaseAuthService.swift \
        SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift
git commit -m "fix: guard Firebase calls when app is not configured"
```

---

## Task 3: Auth and Checkout loading spinners

**Auth:** `AuthViewModel.canSubmit` does not check `isLoading`, so a user can tap Submit multiple
times while a sign-in is in flight. The button stays enabled and no loading state is shown.

**Checkout:** `CheckoutViewModel.canConfirm` already checks `!isLoading`, disabling the button, but
there is no visual indicator that work is happening.

**Files:**
- Modify: `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift` (add `isLoading`)
- Modify: `SushiGarden/Features/Auth/View/AuthContainerView.swift` (spinner in button)
- Modify: `SushiGarden/Features/Checkout/View/CheckoutView.swift` (fullscreen overlay)

- [ ] **Step 1: Add `isLoading` to `AuthViewModel` and include it in `canSubmit`**

In `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift`, after the `mode` property (line 13),
add:

```swift
var isLoading: Bool {
    if case .loading = state { return true }
    return false
}
```

Then update `canSubmit` to guard loading state first:

```swift
var canSubmit: Bool {
    guard !isLoading else { return false }
    let base = FieldValidators.isValidEmail(email) && FieldValidators.isValidPassword(password)
    switch mode {
    case .login: return base
    case .register: return base && FieldValidators.isNonEmpty(name) && consent
    }
}
```

- [ ] **Step 2: Update the submit button in `AuthContainerView` to show a spinner**

In `SushiGarden/Features/Auth/View/AuthContainerView.swift`, replace the submit `Button` label
(the block that currently contains only `Text(Strings.Auth.login.uppercased())`):

```swift
Button(action: {
    Task {
        if let user = await vm.submit() {
            onAuthenticated(user)
        }
    }
}) {
    ZStack {
        if vm.isLoading {
            ProgressView().tint(.white)
        } else {
            Text(Strings.Auth.login.uppercased())
                .font(AppFont.sen(15, bold: true))
                .foregroundStyle(.white)
        }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .background(AppColor.accent)
    .clipShape(RoundedRectangle(cornerRadius: 10))
}
.disabled(!vm.canSubmit)
.opacity(vm.canSubmit ? 1 : 0.95)
.accessibilityIdentifier(A11y.Auth.submit)
```

(Remove the old `.background` and `.clipShape` from the inner `Text` — they now live on the `ZStack`.)

- [ ] **Step 3: Add a full-screen loading overlay to `CheckoutView`**

In `SushiGarden/Features/Checkout/View/CheckoutView.swift`, inside the outermost `ZStack`
(after `ScrollView { ... }.navigationDestination(...)`), add:

```swift
if vm.isLoading {
    Color.black.opacity(0.4).ignoresSafeArea()
    ProgressView().tint(.white).scaleEffect(1.5)
}
```

The full `body` becomes:

```swift
var body: some View {
    ZStack {
        AppColor.background.ignoresSafeArea()
        ScrollView {
            VStack(spacing: Spacing.md) {
                field(Strings.Auth.name, $vm.name, A11y.Checkout.name)
                field(Strings.Checkout.phone, $vm.phone, A11y.Checkout.phone, .phonePad)
                field(Strings.Auth.email, $vm.email, A11y.Checkout.email, .emailAddress)
                summaryRow(Strings.Cart.sum, vm.cartTotal)
                summaryRow(Strings.Cart.delivery, vm.deliveryFee)
                summaryRow(Strings.Cart.serviceFee, vm.serviceFee)
                summaryRow(Strings.Cart.total, vm.total, bold: true)
                Button { Task { await vm.confirm() } } label: {
                    Text(Strings.Cart.confirm)
                        .font(AppFont.sectionHeader).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canConfirm)
                .accessibilityIdentifier(A11y.Checkout.confirm)

                if let msg = vm.errorMessage {
                    Text(msg)
                        .font(AppFont.sen(12))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
        }
        .navigationDestination(isPresented: $goTracking) { TrackingView(deps: deps) }

        if vm.isLoading {
            Color.black.opacity(0.4).ignoresSafeArea()
            ProgressView().tint(.white).scaleEffect(1.5)
        }
    }
    .navigationTitle(Strings.Checkout.address)
    .onChange(of: vm.didConfirm) { _, ok in if ok { goTracking = true } }
}
```

- [ ] **Step 4: Build to confirm no compiler errors**

```bash
xcodebuild build \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 5: Commit**

```bash
git add SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift \
        SushiGarden/Features/Auth/View/AuthContainerView.swift \
        SushiGarden/Features/Checkout/View/CheckoutView.swift
git commit -m "feat: add loading spinners to auth and checkout"
```

---

## Task 4: Cart A11y identifiers for stepper buttons

`CartView` has `+` / `−` buttons and a quantity label per cart row, but they have no
`accessibilityIdentifier`. Without them, UI tests cannot verify quantity changes or test the
stepper — the elements can only be targeted by label text ("+", "−") which is ambiguous when
multiple products are in the cart.

**Files:**
- Modify: `SushiGarden/Resources/A11y.swift:31-36`
- Modify: `SushiGarden/Features/Cart/View/CartView.swift:39-55`

- [ ] **Step 1: Add stepper identifiers to `A11y.swift`**

Replace the `Cart` enum in `SushiGarden/Resources/A11y.swift`:

```swift
enum Cart {
    static let list = "cart.list"
    static let checkout = "cart.checkout"
    static let total = "cart.total"
    static func addon(_ id: String) -> String { "cart.addon.\(id)" }
    static func increment(_ id: String) -> String { "cart.item.\(id).increment" }
    static func decrement(_ id: String) -> String { "cart.item.\(id).decrement" }
    static func quantity(_ id: String) -> String { "cart.item.\(id).qty" }
}
```

- [ ] **Step 2: Apply identifiers in `CartView.row(_:)`**

In `SushiGarden/Features/Cart/View/CartView.swift`, update the stepper `HStack` inside `row(_:)`:

```swift
HStack(spacing: Spacing.md) {
    Button("−") { vm.decrement(item) }
        .font(AppFont.mugesta(20))
        .accessibilityIdentifier(A11y.Cart.decrement(item.product.id))
    Text("\(item.quantity)")
        .foregroundStyle(.white)
        .accessibilityIdentifier(A11y.Cart.quantity(item.product.id))
    Button("+") { vm.increment(item) }
        .font(AppFont.mugesta(20))
        .accessibilityIdentifier(A11y.Cart.increment(item.product.id))
}.foregroundStyle(.white)
```

- [ ] **Step 3: Build to confirm no errors**

```bash
xcodebuild build \
  -project SushiGarden.xcodeproj \
  -scheme SushiGarden \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 4: Commit**

```bash
git add SushiGarden/Resources/A11y.swift \
        SushiGarden/Features/Cart/View/CartView.swift
git commit -m "feat: add accessibility identifiers to cart stepper buttons"
```

---

## Task 5: New and stricter UI tests

Covers: empty cart state, qty stepper, addon total change, auth failure error message,
logout → auth screen, stricter checkout flow assertion, order row text assertion.

**Files:**
- Modify: `SushiGarden/App/Dependencies.swift` (add `-UITEST_AUTH_FAIL` flag)
- Modify: `SushiGardenUITests/CartUITests.swift`
- Modify: `SushiGardenUITests/AuthFlowUITests.swift`
- Modify: `SushiGardenUITests/CheckoutUITests.swift`
- Modify: `SushiGardenUITests/OrdersUITests.swift`

- [ ] **Step 1: Add `-UITEST_AUTH_FAIL` support to `Dependencies`**

In `SushiGarden/App/Dependencies.swift`, inside the `if uiTest { }` block, update FakeAuthService
creation:

```swift
if uiTest {
    let seeded = launchArguments.contains("-SEEDED_AUTH")
        ? UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru") : nil
    let shouldFail = launchArguments.contains("-UITEST_AUTH_FAIL")
    self.auth = FakeAuthService(seeded: seeded, shouldFail: shouldFail)
} else {
    self.auth = FirebaseAuthService()
}
```

- [ ] **Step 2: Add three new tests to `CartUITests.swift`**

```swift
func test_emptyCart_checkoutButtonDisabled() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
    app.launch()
    app.buttons["tab.cart"].tap()
    // No items added — checkout button must be disabled
    XCTAssertFalse(app.buttons["cart.checkout"].isEnabled)
}

func test_stepperIncrement_updatesQuantity() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_CART"]
    app.launch()
    app.buttons["tab.cart"].tap()
    XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
    // Seeded cart has hikari (qty 1) and la (qty 1)
    let qtyLabel = app.staticTexts["cart.item.hikari.qty"]
    XCTAssertTrue(qtyLabel.waitForExistence(timeout: 3))
    XCTAssertEqual(qtyLabel.label, "1")
    app.buttons["cart.item.hikari.increment"].tap()
    XCTAssertEqual(qtyLabel.label, "2")
    app.buttons["cart.item.hikari.decrement"].tap()
    XCTAssertEqual(qtyLabel.label, "1")
}

func test_addonToggle_changesCheckoutButtonTotal() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_CART"]
    app.launch()
    app.buttons["tab.cart"].tap()
    XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
    let checkoutBtn = app.buttons["cart.checkout"]
    let labelBefore = checkoutBtn.label
    // Toggle wasabi add-on (60 ₽)
    XCTAssertTrue(app.buttons["cart.addon.wasabi"].waitForExistence(timeout: 3))
    app.buttons["cart.addon.wasabi"].tap()
    // Checkout button label embeds the total — it must change
    XCTAssertNotEqual(checkoutBtn.label, labelBefore)
}
```

- [ ] **Step 3: Add two new tests to `AuthFlowUITests.swift`**

```swift
func test_login_failure_showsErrorMessage() {
    let app = XCUIApplication()
    // -UITEST_AUTH_FAIL makes FakeAuthService.signIn throw .invalidCredentials
    app.launchArguments = ["-UITEST", "-AUTH_LOGIN", "-UITEST_AUTH_FAIL"]
    app.launch()
    app.textFields["auth.email"].tap()
    app.typeText("a@b.ru")
    app.buttons["auth.password.visibility"].tap()
    app.textFields["auth.password"].tap()
    app.typeText("123456")
    XCTAssertTrue(app.buttons["auth.submit"].waitForExistence(timeout: 3))
    app.buttons["auth.submit"].tap()
    // FakeAuthService throws .invalidCredentials → AuthViewModel maps to Russian string
    XCTAssertTrue(app.staticTexts["Неверная почта или пароль"].waitForExistence(timeout: 5))
}

func test_logout_returnsToAuthScreen() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
    app.launch()
    app.buttons["tab.profile"].tap()
    XCTAssertTrue(app.buttons["profile.logout"].waitForExistence(timeout: 5))
    app.buttons["profile.logout"].tap()
    // After logout, auth screen (email field) must appear
    XCTAssertTrue(app.textFields["auth.email"].waitForExistence(timeout: 5))
}
```

- [ ] **Step 4: Strengthen `CheckoutUITests.swift`**

The existing test `test_checkoutFlow_confirmsOrder` only verifies the confirm button is
enabled — it does not tap it or verify the result. Replace the method body:

```swift
func test_checkoutFlow_confirmsOrder() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
    app.launch()
    app.buttons["tab.catalog"].tap()
    XCTAssertTrue(app.buttons["catalog.card.la"].waitForExistence(timeout: 5))
    app.buttons["catalog.card.la"].tap()
    XCTAssertTrue(app.buttons["detail.add"].waitForExistence(timeout: 5))
    app.buttons["detail.add"].tap()
    app.buttons["tab.cart"].tap()
    XCTAssertTrue(app.buttons["cart.checkout"].waitForExistence(timeout: 5))
    app.buttons["cart.checkout"].tap()

    let nameField = app.textFields["checkout.name"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    nameField.tap(); app.typeText("Саша")
    app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
    app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
    nameField.tap() // dismiss keyboard

    XCTAssertTrue(app.buttons["checkout.confirm"].isEnabled,
                  "Confirm must be enabled after valid form entry")
    app.buttons["checkout.confirm"].tap()

    // Tracking view must appear after confirming
    XCTAssertTrue(app.otherElements["tracking.map"].waitForExistence(timeout: 10),
                  "TrackingView did not appear after checkout confirm")
}
```

- [ ] **Step 5: Strengthen `OrdersUITests.swift` — assert actual order text**

The existing test only checks that `orders.list` exists. Add an assertion that a row with text
starting "Заказ №" is visible:

Replace the end of `test_placedOrderAppearsInOrdersTab`:

```swift
// ... (keep navigation steps up to) ...
_ = app.otherElements["tracking.courier"].waitForExistence(timeout: 8)
app.buttons["tab.orders"].tap()
XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
// Verify an actual order row (not just the container)
let orderRow = app.staticTexts
    .matching(NSPredicate(format: "label BEGINSWITH 'Заказ №'"))
    .firstMatch
XCTAssertTrue(orderRow.waitForExistence(timeout: 3),
              "No order row found in orders list after placing an order")
```

- [ ] **Step 6: Run all UI tests**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGardenUITests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  2>&1 | grep -E "(PASS|FAIL|error:)" | tail -30
```

Expected: all UI tests **PASS**.

- [ ] **Step 7: Commit**

```bash
git add SushiGarden/App/Dependencies.swift \
        SushiGardenUITests/CartUITests.swift \
        SushiGardenUITests/AuthFlowUITests.swift \
        SushiGardenUITests/CheckoutUITests.swift \
        SushiGardenUITests/OrdersUITests.swift
git commit -m "test: stricter UI tests — empty cart, steppers, addons, auth error, logout, tracking assertion"
```

---

## Task 6: Order detail view

`OrdersView` shows each order as a single row (ID prefix + total). There is no drill-down to see
individual items. This task adds `OrderDetailView` and wires it up via `NavigationLink`.

**Files:**
- Create: `SushiGarden/Features/Orders/View/OrderDetailView.swift`
- Modify: `SushiGarden/Features/Orders/View/OrdersView.swift:24-37`
- Modify: `SushiGarden/Resources/A11y.swift:44`

- [ ] **Step 1: Write a failing UI test for order detail**

Add a new test to `SushiGardenUITests/OrdersUITests.swift`:

```swift
func test_seededOrder_canOpenDetail() {
    let app = XCUIApplication()
    // -SEEDED_ORDERS seeds two orders; -START_TAB=2 opens the Orders tab directly
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_ORDERS", "-START_TAB=2"]
    app.launch()
    XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
    // Tap the first order row
    let orderRow = app.staticTexts
        .matching(NSPredicate(format: "label BEGINSWITH 'Заказ №'"))
        .firstMatch
    XCTAssertTrue(orderRow.waitForExistence(timeout: 3))
    orderRow.tap()
    // OrderDetailView must appear with its list identifier
    XCTAssertTrue(app.otherElements["orders.detail.list"].waitForExistence(timeout: 5),
                  "OrderDetailView did not appear after tapping order row")
    // First seeded order contains "Хикари"
    XCTAssertTrue(
        app.staticTexts["Хикари"].waitForExistence(timeout: 3),
        "Expected 'Хикари' line in order detail"
    )
}
```

- [ ] **Step 2: Run to verify the test fails**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGardenUITests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenUITests/OrdersUITests/test_seededOrder_canOpenDetail \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```

Expected: **FAIL** — tapping the row does nothing (no NavigationLink yet).

- [ ] **Step 3: Add Order detail identifiers to `A11y.swift`**

Replace the `Orders` enum in `SushiGarden/Resources/A11y.swift`:

```swift
enum Orders {
    static let list = "orders.list"
    static let empty = "orders.empty"
    static let detailList = "orders.detail.list"
    static func detailLine(_ name: String) -> String { "orders.detail.line.\(name)" }
}
```

- [ ] **Step 4: Create `OrderDetailView.swift`**

Create `SushiGarden/Features/Orders/View/OrderDetailView.swift`:

```swift
import SwiftUI

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(order.lines, id: \.name) { line in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.name)
                                    .font(AppFont.productTitle)
                                    .foregroundStyle(.white)
                                Text("× \(line.quantity)")
                                    .font(AppFont.weight)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer()
                            Text("\(line.priceRub * line.quantity) \(Strings.currency)")
                                .font(AppFont.weight)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.screenMargin)
                        .padding(.vertical, Spacing.sm)
                        .accessibilityIdentifier(A11y.Orders.detailLine(line.name))
                    }
                    Divider().overlay(AppColor.textSecondary.opacity(0.4))
                    HStack {
                        Text(Strings.Cart.total)
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(order.totalRub) \(Strings.currency)")
                            .font(AppFont.price)
                            .foregroundStyle(AppColor.accent)
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                    .padding(.vertical, Spacing.sm)
                }
                .accessibilityIdentifier(A11y.Orders.detailList)
            }
        }
        .navigationTitle(Strings.Orders.row(String(order.id.prefix(6))))
    }
}
```

- [ ] **Step 5: Add `NavigationLink` to `OrdersView`**

In `SushiGarden/Features/Orders/View/OrdersView.swift`, replace the `ForEach` content inside
`LazyVStack`:

```swift
ForEach(vm.orders) { o in
    NavigationLink(destination: OrderDetailView(order: o)) {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Orders.row(String(o.id.prefix(6))))
                .font(AppFont.productTitle)
                .foregroundStyle(.white)
            Text("\(o.totalRub) \(Strings.currency)")
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(AppColor.tabBar)
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 6: Run the UI test, confirm it passes**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGardenUITests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenUITests/OrdersUITests/test_seededOrder_canOpenDetail \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```

Expected: **PASS**.

- [ ] **Step 7: Commit**

```bash
git add SushiGarden/Features/Orders/View/OrderDetailView.swift \
        SushiGarden/Features/Orders/View/OrdersView.swift \
        SushiGarden/Resources/A11y.swift \
        SushiGardenUITests/OrdersUITests.swift
git commit -m "feat: add order detail view with line breakdown"
```

---

## Task 7: Profile phone field

`ProfileView` shows name, email, order count, and a logout button. There is no way to store or
display a phone number. This task adds an editable `TextField` that persists to `UserDefaults`
(no Firebase write — phone is local-only, visible only on this device).

**Files:**
- Modify: `SushiGarden/Features/Profile/View/ProfileView.swift`
- Modify: `SushiGarden/Resources/A11y.swift`

- [ ] **Step 1: Write a failing UI test**

Add to `SushiGardenUITests/ProfileUITests.swift` (or create it if it only has a placeholder):

```swift
func test_phone_fieldIsVisibleAndEditable() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
    app.launch()
    app.buttons["tab.profile"].tap()
    let phoneField = app.textFields["profile.phone"]
    XCTAssertTrue(phoneField.waitForExistence(timeout: 5),
                  "Phone text field must exist in ProfileView")
    phoneField.tap()
    app.typeText("+79001234567")
    XCTAssertEqual(phoneField.value as? String, "+79001234567")
}
```

- [ ] **Step 2: Run to verify the test fails**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGardenUITests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenUITests/ProfileUITests/test_phone_fieldIsVisibleAndEditable \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```

Expected: **FAIL** — `profile.phone` does not exist.

- [ ] **Step 3: Add `Profile.phone` identifier to `A11y.swift`**

Replace the `Profile` enum:

```swift
enum Profile {
    static let logout = "profile.logout"
    static let name = "profile.name"
    static let phone = "profile.phone"
}
```

- [ ] **Step 4: Add editable phone field to `ProfileView`**

Replace the entire `ProfileView` struct in
`SushiGarden/Features/Profile/View/ProfileView.swift`:

```swift
// SushiGarden/Features/Profile/View/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    let deps: Dependencies
    let user: UserProfile
    let onLogout: () -> Void
    @StateObject private var vm: ProfileViewModel
    @State private var phone = UserDefaults.standard.string(forKey: "sg.profile.phone") ?? ""

    init(deps: Dependencies, user: UserProfile, onLogout: @escaping () -> Void) {
        self.deps = deps
        self.user = user
        self.onLogout = onLogout
        _vm = StateObject(wrappedValue: ProfileViewModel(user: user, orders: deps.orders))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(AppColor.textSecondary)

                    Text(vm.user.name)
                        .font(AppFont.sen(20, bold: true))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier(A11y.Profile.name)

                    Text(vm.user.email)
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .font(AppFont.sen(15))
                        .padding(.horizontal, Spacing.screenMargin)
                        .onChange(of: phone) { _, newVal in
                            UserDefaults.standard.set(newVal, forKey: "sg.profile.phone")
                        }
                        .accessibilityIdentifier(A11y.Profile.phone)

                    Text("\(Strings.Profile.myOrders): \(vm.recentOrders.count)")
                        .foregroundStyle(.white)

                    Spacer()

                    Button(Strings.Profile.logout, role: .destructive, action: onLogout)
                        .tint(AppColor.accent)
                        .accessibilityIdentifier(A11y.Profile.logout)
                }
                .padding(Spacing.screenMargin)
            }
            .navigationTitle(Strings.Tabs.profile)
            .onAppear { vm.load() }
        }
        .tint(AppColor.accent)
    }
}
```

- [ ] **Step 5: Run the UI test, confirm it passes**

```bash
xcodebuild test \
  -project SushiGarden.xcodeproj \
  -scheme SushiGardenUITests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:SushiGardenUITests/ProfileUITests/test_phone_fieldIsVisibleAndEditable \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```

Expected: **PASS**.

- [ ] **Step 6: Commit**

```bash
git add SushiGarden/Features/Profile/View/ProfileView.swift \
        SushiGarden/Resources/A11y.swift \
        SushiGardenUITests/ProfileUITests.swift
git commit -m "feat: add editable phone field to profile (UserDefaults)"
```

---

## Summary of changes

| Area | What changed | Why |
|------|-------------|-----|
| `AuthViewModel.canSubmit` | Added `&& consent` for register; `&& !isLoading` for all modes | Registration allowed without consent; double-submit on slow network |
| `FirebaseAuthService` | Guards in signUp/signIn/signOut | Crash if Firebase not configured |
| Auth/Checkout UI | Loading spinners | No visual feedback during async work |
| `CartView` | A11y identifiers on stepper | Required for UI tests of qty changes |
| `Dependencies` | `-UITEST_AUTH_FAIL` flag | Enable auth-failure UI test scenario |
| UI tests | 8 new tests; 2 tests strengthened | Coverage gaps: empty cart, steppers, addons, auth errors, logout, order detail |
| `OrderDetailView` | New view | No way to see order line breakdown |
| `ProfileView` | Editable phone TextField | Profile had no contact info field |
