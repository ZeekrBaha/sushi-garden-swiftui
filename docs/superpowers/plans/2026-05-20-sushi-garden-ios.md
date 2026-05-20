# Sushi Garden iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Sushi Garden Russian-language sushi-delivery iOS app from the Figma design — SwiftUI + MVVM + async/await, Firebase Auth for sign-up/login, local mock data for everything else, a simulated MapKit delivery map, and UI tests for every screen.

**Architecture:** UIKit `AppDelegate`+`SceneDelegate` shell (so Firebase configures at launch and routing can swap root between the Auth flow and a 5-tab `RootTabBarController`) hosting SwiftUI screens via `UIHostingController`. Each screen is a Feature folder with a SwiftUI `View` and a `@MainActor` observable `ViewModel` that depends only on service protocols injected through a `Dependencies` container. Auth is the only networked service; menu/cart/promotions are local mock data, placed orders persist via SwiftData, and the delivery map is driven by an offline `CourierSimulator`.

**Tech Stack:** Swift 5.10 / Xcode 16, iOS 17, XcodeGen, FirebaseAuth (SPM), SwiftData, MapKit, XCTest + XCUITest. Fonts: Sen (bundled) + Mugesta (user-supplied, SF Symbols fallback).

---

## Conventions for every task

- **TDD:** write the failing test, run it to confirm it fails, write minimal code, run to confirm it passes, commit. (Per the user's global rule.)
- **Build/test simulator:** `iPhone 16 Pro Max` (closest to the 430×932 Figma frame).
- **Regenerate the Xcode project** whenever files are added/removed: `xcodegen generate` (run from repo root). `*.xcodeproj` is git-ignored.
- **Unit test command:**
  ```bash
  xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    -only-testing:SushiGardenTests 2>&1 | xcbeautify
  ```
  (If `xcbeautify` is absent, drop the pipe.)
- **UI test command:** same as above with `-only-testing:SushiGardenUITests`.
- **Russian strings** live in `SushiGarden/Resources/Strings.swift` as a `Strings` enum so tests can reference them without hardcoding literals in two places.
- **Accessibility identifiers** live in `SushiGarden/Resources/A11y.swift` as an `A11y` enum, shared by views and UI tests.
- **Commit messages** end with the Co-Authored-By trailer:
  ```
  Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
  ```

## File map (created across the plan)

```
project.yml
scripts/extract-figma-assets.sh
SushiGarden/
  App/ AppDelegate.swift SceneDelegate.swift RootTabBarController.swift
       Dependencies.swift Info.plist LaunchScreen.storyboard
  Resources/ Strings.swift A11y.swift Assets.xcassets/
  DesignSystem/ Colors.swift Typography.swift Spacing.swift Fonts/(Sen,Mugesta)
  SharedModels/ Product.swift Category.swift AddOn.swift CartItem.swift
                Order.swift UserProfile.swift Courier.swift DeliveryAddress.swift
  Services/
    Auth/ AuthService.swift FirebaseAuthService.swift FakeAuthService.swift
    Catalog/ MenuRepository.swift
    Cart/ CartService.swift
    Orders/ OrderStore.swift
    Delivery/ CourierSimulator.swift
    Validation/ FieldValidators.swift
  Features/
    Auth/ View/ RegisterView.swift LoginView.swift  ViewModel/ AuthViewModel.swift
    Catalog/ View/ CatalogView.swift ProductCardView.swift  ViewModel/ CatalogViewModel.swift
    ProductDetail/ View/ ProductDetailView.swift  ViewModel/ ProductDetailViewModel.swift
    Promotions/ View/ PromotionsView.swift  ViewModel/ PromotionsViewModel.swift
    Cart/ View/ CartView.swift  ViewModel/ CartViewModel.swift
    Checkout/ View/ CheckoutView.swift  ViewModel/ CheckoutViewModel.swift
    Tracking/ View/ TrackingView.swift  ViewModel/ TrackingViewModel.swift
    Orders/ View/ OrdersView.swift  ViewModel/ OrdersViewModel.swift
    Profile/ View/ ProfileView.swift  ViewModel/ ProfileViewModel.swift
SushiGardenTests/...
SushiGardenUITests/...
```

---

# Phase 0 — Scaffold

### Task 0.1: XcodeGen project + folder skeleton

**Files:**
- Create: `project.yml`
- Create: `SushiGarden/App/Info.plist`
- Create: `SushiGarden/App/AppDelegate.swift` (minimal)
- Create: `SushiGarden/App/SceneDelegate.swift` (minimal)
- Create: `SushiGardenTests/SmokePlaceholderTests.swift`
- Create: `SushiGardenUITests/SmokePlaceholderTests.swift`

- [ ] **Step 1: Write `project.yml`**

```yaml
name: SushiGarden
options:
  bundleIdPrefix: com.baha
  deploymentTarget:
    iOS: "17.0"
  developmentLanguage: ru
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "5.10"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    CODE_SIGNING_REQUIRED: NO
    CODE_SIGNING_ALLOWED: NO

packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk.git
    from: "11.0.0"

targets:
  SushiGarden:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: SushiGarden
        excludes:
          - "DesignSystem/Fonts/**"
      - path: SushiGarden/DesignSystem/Fonts
        type: folder
        buildPhase: resources
    dependencies:
      - package: Firebase
        product: FirebaseAuth
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.baha.sushigarden
        INFOPLIST_FILE: SushiGarden/App/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ENABLE_PREVIEWS: NO

  SushiGardenTests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "17.0"
    sources: [SushiGardenTests]
    dependencies:
      - target: SushiGarden
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.baha.sushigarden.tests
        GENERATE_INFOPLIST_FILE: YES

  SushiGardenUITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "17.0"
    sources: [SushiGardenUITests]
    dependencies:
      - target: SushiGarden
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.baha.sushigarden.uitests
        GENERATE_INFOPLIST_FILE: YES

schemes:
  SushiGarden:
    build:
      targets:
        SushiGarden: all
        SushiGardenTests: [test]
        SushiGardenUITests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets:
        - SushiGardenTests
        - SushiGardenUITests
```

- [ ] **Step 2: Write `SushiGarden/App/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key><string>Sushi Garden</string>
  <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
  <key>CFBundleShortVersionString</key><string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>
  <key>UILaunchStoryboardName</key><string>LaunchScreen</string>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key><false/>
    <key>UISceneConfigurations</key>
    <dict>
      <key>UIWindowSceneSessionRoleApplication</key>
      <array><dict>
        <key>UISceneConfigurationName</key><string>Default Configuration</string>
        <key>UISceneDelegateClassName</key><string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
      </dict></array>
    </dict>
  </dict>
  <key>UISupportedInterfaceOrientations</key>
  <array><string>UIInterfaceOrientationPortrait</string></array>
  <key>UIAppFonts</key>
  <array>
    <string>Sen-Regular.ttf</string>
    <string>Sen-Bold.ttf</string>
    <string>Mugesta.ttf</string>
  </array>
</dict>
</plist>
```

- [ ] **Step 3: Minimal `AppDelegate.swift` and `SceneDelegate.swift`** (replaced fully in Phase 1; just enough to launch)

```swift
// SushiGarden/App/AppDelegate.swift
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        true
    }
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
```

```swift
// SushiGarden/App/SceneDelegate.swift
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        window.rootViewController = vc
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

- [ ] **Step 4: Add `LaunchScreen.storyboard`**

```bash
mkdir -p SushiGarden/App
cat > SushiGarden/App/LaunchScreen.storyboard <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="22685" targetRuntime="iOS.CocoaTouch" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
  <scenes><scene sceneID="EHf-IW-A2E"><objects>
    <viewController id="01J-lp-oVM" sceneMemberID="viewController">
      <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
        <rect key="frame" x="0.0" y="0.0" width="430" height="932"/>
        <color key="backgroundColor" red="0.058" green="0.058" blue="0.066" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
      </view>
    </viewController>
    <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" sceneMemberID="firstResponder"/>
  </objects></scene></scenes>
</document>
EOF
```

- [ ] **Step 5: Placeholder smoke tests** (so both test bundles compile from the start)

```swift
// SushiGardenTests/SmokePlaceholderTests.swift
import XCTest
final class SmokePlaceholderTests: XCTestCase {
    func test_truth() { XCTAssertTrue(true) }
}
```

```swift
// SushiGardenUITests/SmokePlaceholderTests.swift
import XCTest
final class UISmokePlaceholderTests: XCTestCase {
    func test_launch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
```

- [ ] **Step 6: Generate project and build**

Run:
```bash
xcodegen generate
xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **` (SPM resolves FirebaseAuth on first run; this may take a few minutes).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Scaffold SushiGarden XcodeGen project and app shell

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 0.2: Design system (colors, spacing, typography)

Color values are taken from the Figma JSON (sRGB 0–1 → hex).

**Files:**
- Create: `SushiGarden/DesignSystem/Colors.swift`
- Create: `SushiGarden/DesignSystem/Spacing.swift`
- Create: `SushiGarden/DesignSystem/Typography.swift`
- Test: `SushiGardenTests/DesignSystem/ColorsTests.swift`

- [ ] **Step 1: Failing test for the color palette presence**

```swift
// SushiGardenTests/DesignSystem/ColorsTests.swift
import SwiftUI
import XCTest
@testable import SushiGarden

final class ColorsTests: XCTestCase {
    func test_accentRed_isDefined() {
        // Accent red #EC1A35 from Figma delivery pin / primary buttons
        let c = UIColor(AppColor.accent).cgColor.components ?? []
        XCTAssertEqual(c[0], 0.925, accuracy: 0.01)
        XCTAssertEqual(c[1], 0.102, accuracy: 0.01)
        XCTAssertEqual(c[2], 0.208, accuracy: 0.01)
    }
}
```

- [ ] **Step 2: Run, confirm fail** (`AppColor` undefined). Run the unit test command. Expected: compile failure.

- [ ] **Step 3: Implement**

```swift
// SushiGarden/DesignSystem/Colors.swift
import SwiftUI

enum AppColor {
    /// App background #0F0F11
    static let background = Color(red: 0.058, green: 0.058, blue: 0.066)
    /// Tab bar background #161616
    static let tabBar = Color(red: 0.0875, green: 0.0875, blue: 0.0875)
    /// Card price pill #29282C
    static let pricePill = Color(red: 0.161, green: 0.157, blue: 0.173)
    /// Primary accent red #EC1A35
    static let accent = Color(red: 0.925, green: 0.102, blue: 0.208)
    static let textPrimary = Color.white
    /// Weight/secondary gray #6C6C74
    static let textSecondary = Color(red: 0.423, green: 0.423, blue: 0.455)
    /// Inactive tab/icon #4C4C4C
    static let inactive = Color(red: 0.2997, green: 0.2997, blue: 0.2997)
}
```

```swift
// SushiGarden/DesignSystem/Spacing.swift
import CoreGraphics

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let screenMargin: CGFloat = 25   // Figma 5-col grid offset
    static let cardCorner: CGFloat = 12.4
    static let bannerCorner: CGFloat = 21
}
```

```swift
// SushiGarden/DesignSystem/Typography.swift
import SwiftUI

enum AppFont {
    static func sen(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Sen-Bold" : "Sen-Regular", size: size)
    }
    /// Mugesta for stepper glyphs; falls back to SF if the font is absent.
    static func mugesta(_ size: CGFloat) -> Font {
        UIFont(name: "Mugesta", size: size) != nil
            ? .custom("Mugesta", size: size)
            : .system(size: size, weight: .regular)
    }
    // Semantic styles (sizes from Figma)
    static var price: Font { sen(19.3, bold: true) }
    static var productTitle: Font { sen(16.6, bold: true) }
    static var sectionHeader: Font { sen(15.8, bold: true) }
    static var weight: Font { sen(14.2) }
    static var tabLabel: Font { sen(11.8) }
}
```

- [ ] **Step 4: Run test, confirm pass.**

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Add design system (colors, spacing, typography)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 0.3: Bundle Sen font + register loader, Mugesta fallback

**Files:**
- Create: `SushiGarden/DesignSystem/Fonts/Sen-Regular.ttf`, `Sen-Bold.ttf` (downloaded)
- Create: `SushiGarden/DesignSystem/Fonts/.gitkeep` (for Mugesta slot)
- Create: `SushiGarden/DesignSystem/FontLoader.swift`
- Test: `SushiGardenTests/DesignSystem/FontLoaderTests.swift`

- [ ] **Step 1: Download Sen from Google Fonts**

```bash
mkdir -p SushiGarden/DesignSystem/Fonts
curl -sL "https://github.com/google/fonts/raw/main/ofl/sen/static/Sen-Regular.ttf" \
  -o SushiGarden/DesignSystem/Fonts/Sen-Regular.ttf
curl -sL "https://github.com/google/fonts/raw/main/ofl/sen/static/Sen-Bold.ttf" \
  -o SushiGarden/DesignSystem/Fonts/Sen-Bold.ttf
file SushiGarden/DesignSystem/Fonts/Sen-*.ttf   # expect "TrueType Font data"
```
> **User dependency:** drop `Mugesta.ttf` into the same folder when available. Until then the stepper uses the SF fallback in `AppFont.mugesta`; `Info.plist` already lists `Mugesta.ttf` (a missing entry is ignored at runtime).

- [ ] **Step 2: Failing test that Sen registers**

```swift
// SushiGardenTests/DesignSystem/FontLoaderTests.swift
import UIKit
import XCTest
@testable import SushiGarden

final class FontLoaderTests: XCTestCase {
    func test_senRegular_isAvailable() {
        XCTAssertNotNil(UIFont(name: "Sen-Regular", size: 16))
    }
    func test_senBold_isAvailable() {
        XCTAssertNotNil(UIFont(name: "Sen-Bold", size: 16))
    }
}
```

- [ ] **Step 3: Run, confirm fail** (fonts not in test bundle yet). Because fonts are a resource of the app target, the unit-test target loads them from the host app. Add a no-op loader to guarantee registration even under tests:

```swift
// SushiGarden/DesignSystem/FontLoader.swift
import CoreText
import Foundation

enum FontLoader {
    /// Idempotent. Registers bundled fonts; safe if already registered or missing.
    static func registerAll() {
        for name in ["Sen-Regular", "Sen-Bold", "Mugesta"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
```

- [ ] **Step 4: Call `FontLoader.registerAll()`** at the top of `AppDelegate.application(_:didFinishLaunchingWithOptions:)`. Run tests, confirm pass.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Bundle Sen fonts and font loader (Mugesta fallback)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 0.4: Extract Figma images into Assets.xcassets

The Figma JSON references image fills by `imageRef` and renderable nodes (banners/logo/avatar). This task adds a script that pulls them with the Figma REST API using the token already stored in the MCP config.

**Files:**
- Create: `scripts/extract-figma-assets.sh`
- Create (generated): `SushiGarden/Resources/Assets.xcassets/**` imagesets

- [ ] **Step 1: Write the extraction script**

```bash
# scripts/extract-figma-assets.sh
#!/usr/bin/env bash
set -euo pipefail
FILE_KEY="wOK1MMzuJZF3pIOZhGHpY9"
OUT="SushiGarden/Resources/Assets.xcassets"
# Token: reuse the Figma MCP token from ~/.claude.json, or export FIGMA_TOKEN.
TOKEN="${FIGMA_TOKEN:-$(python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude.json')));import re;print(next((v for k,v in json.dumps(d).split() if False), ''))" 2>/dev/null || true)}"
if [ -z "${TOKEN:-}" ]; then echo "Set FIGMA_TOKEN env var (Figma personal access token)"; exit 1; fi
mkdir -p "$OUT"

# 1) Resolve all imageRef fills -> temporary URLs
curl -s -H "X-Figma-Token: $TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/images" > /tmp/figma_images.json
echo "Saved imageRef->url map to /tmp/figma_images.json"

# 2) Helper: download one imageRef into a named imageset
dl_ref () { # $1=imageRef  $2=assetName
  local url; url=$(python3 -c "import json,sys;print(json.load(open('/tmp/figma_images.json'))['meta']['images'].get('$1',''))")
  [ -z "$url" ] && { echo "missing ref $1"; return; }
  mkdir -p "$OUT/$2.imageset"
  curl -sL "$url" -o "$OUT/$2.imageset/$2.png"
  cat > "$OUT/$2.imageset/Contents.json" <<JSON
{ "images": [ { "idiom":"universal", "filename":"$2.png", "scale":"1x" } ],
  "info": { "author":"xcode", "version":1 } }
JSON
}

# Product photo imageRefs found in the Figma JSON:
dl_ref 9a47d23289a5f8037d0a221a4d5c1705288072b3 product_hikari
dl_ref 63f9d6bca62b86fcfdaaa76cc3413db2afdfed82 product_la
dl_ref 831991b082d35d478e048b042aa1dd799cb0f209 product_idaho
dl_ref 16ec23a7ff3b383d2e3f28aab00baa2f317011d1 product_osaka

# 3) Render nodes that are not plain image fills (banners/logo/avatar)
#    node ids from the Figma canvas: banners 1:1369 / 1:1370, hot promo, avatar
render_node () { # $1=nodeId  $2=assetName
  local id="$1"; local url
  url=$(curl -s -H "X-Figma-Token: $TOKEN" \
    "https://api.figma.com/v1/images/$FILE_KEY?ids=$id&format=png&scale=2" \
    | python3 -c "import json,sys;d=json.load(sys.stdin);print(list(d['images'].values())[0] or '')")
  [ -z "$url" ] && { echo "missing node $id"; return; }
  mkdir -p "$OUT/$2.imageset"
  curl -sL "$url" -o "$OUT/$2.imageset/$2.png"
  cat > "$OUT/$2.imageset/Contents.json" <<JSON
{ "images": [ { "idiom":"universal", "filename":"$2.png", "scale":"2x" } ],
  "info": { "author":"xcode", "version":1 } }
JSON
}

render_node 1:1370 banner_promo_1
render_node 1:1369 banner_promo_2

echo "Done. Review $OUT before committing."
```

- [ ] **Step 2: Run it** (token from the user's Figma MCP setup; export if the auto-read fails)

```bash
chmod +x scripts/extract-figma-assets.sh
FIGMA_TOKEN=<your_figma_token> ./scripts/extract-figma-assets.sh
ls -R SushiGarden/Resources/Assets.xcassets
```
Expected: `product_hikari.imageset/product_hikari.png` etc. present and non-zero. If a `render_node` returns empty, open the node in Figma → Export to confirm the id, or fall back to the thumbnail.

> If the token is unavailable at execution time, create the four `product_*` imagesets with solid-color placeholder PNGs so the build is unblocked, and leave a note to re-run the script later. Do **not** leave imagesets empty (Xcode warns).

- [ ] **Step 3: Add an `AppImage` accessor**

```swift
// SushiGarden/Resources/AppImage.swift
import SwiftUI
enum AppImage {
    static let hikari = Image("product_hikari")
    static let losAngeles = Image("product_la")
    static let idaho = Image("product_idaho")
    static let osaka = Image("product_osaka")
    static let bannerPromo1 = Image("banner_promo_1")
    static let bannerPromo2 = Image("banner_promo_2")
}
```

- [ ] **Step 4: Regenerate, build, commit**

```bash
xcodegen generate
xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' 2>&1 | tail -5
git add -A && git commit -m "Extract Figma image assets and add AppImage accessor

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 0.5: Shared string & accessibility-id catalogs

**Files:**
- Create: `SushiGarden/Resources/Strings.swift`
- Create: `SushiGarden/Resources/A11y.swift`

- [ ] **Step 1: Implement (no test; referenced by later tests)**

```swift
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
```

```swift
// SushiGarden/Resources/A11y.swift
enum A11y {
    enum Auth {
        static let nameField = "auth.name"
        static let emailField = "auth.email"
        static let passwordField = "auth.password"
        static let submit = "auth.submit"
        static let toggleMode = "auth.toggleMode"
        static let consentToggle = "auth.consent"
    }
    enum Tabs {
        static let bar = "tabbar"
        static let catalog = "tab.catalog"
        static let promotions = "tab.promotions"
        static let orders = "tab.orders"
        static let cart = "tab.cart"
        static let profile = "tab.profile"
    }
    enum Catalog {
        static let grid = "catalog.grid"
        static func card(_ id: String) -> String { "catalog.card.\(id)" }
        static func category(_ name: String) -> String { "catalog.category.\(name)" }
    }
    enum Detail {
        static let addToCart = "detail.add"
        static let stepperPlus = "detail.plus"
        static let stepperMinus = "detail.minus"
        static let quantity = "detail.qty"
    }
    enum Cart {
        static let list = "cart.list"
        static let checkout = "cart.checkout"
        static let total = "cart.total"
        static func addon(_ id: String) -> String { "cart.addon.\(id)" }
    }
    enum Checkout {
        static let name = "checkout.name"
        static let phone = "checkout.phone"
        static let email = "checkout.email"
        static let confirm = "checkout.confirm"
    }
    enum Tracking { static let map = "tracking.map"; static let courier = "tracking.courier" }
    enum Orders { static let list = "orders.list"; static let empty = "orders.empty" }
    enum Profile { static let logout = "profile.logout"; static let name = "profile.name" }
}
```

- [ ] **Step 2: Regenerate + build + commit**

```bash
xcodegen generate
git add -A && git commit -m "Add shared Russian strings and a11y identifier catalogs

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

# Phase 1 — App shell, DI, Auth, routing

### Task 1.1: Domain model — UserProfile

**Files:**
- Create: `SushiGarden/SharedModels/UserProfile.swift`
- Test: `SushiGardenTests/SharedModels/UserProfileTests.swift`

- [ ] **Step 1: Failing test**

```swift
// SushiGardenTests/SharedModels/UserProfileTests.swift
import XCTest
@testable import SushiGarden

final class UserProfileTests: XCTestCase {
    func test_init_storesFields() {
        let u = UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru")
        XCTAssertEqual(u.id, "u1")
        XCTAssertEqual(u.name, "Александр Новиков")
        XCTAssertEqual(u.email, "a@b.ru")
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/SharedModels/UserProfile.swift
import Foundation
struct UserProfile: Equatable, Identifiable {
    let id: String
    let name: String
    let email: String
}
```

- [ ] **Step 4: Run pass. Step 5: Commit** `git add -A && git commit -m "Add UserProfile model" -m "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"`

---

### Task 1.2: Field validators

**Files:**
- Create: `SushiGarden/Services/Validation/FieldValidators.swift`
- Test: `SushiGardenTests/Services/FieldValidatorsTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Services/FieldValidatorsTests.swift
import XCTest
@testable import SushiGarden

final class FieldValidatorsTests: XCTestCase {
    func test_email_valid() { XCTAssertTrue(FieldValidators.isValidEmail("a@b.ru")) }
    func test_email_invalid() {
        XCTAssertFalse(FieldValidators.isValidEmail("a@b"))
        XCTAssertFalse(FieldValidators.isValidEmail(""))
    }
    func test_password_minLength() {
        XCTAssertTrue(FieldValidators.isValidPassword("123456"))
        XCTAssertFalse(FieldValidators.isValidPassword("123"))
    }
    func test_phone_digitsCount() {
        XCTAssertTrue(FieldValidators.isValidPhone("+7 900 123 45 67"))
        XCTAssertFalse(FieldValidators.isValidPhone("123"))
    }
    func test_nonEmptyName() {
        XCTAssertTrue(FieldValidators.isNonEmpty(" Саша "))
        XCTAssertFalse(FieldValidators.isNonEmpty("   "))
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Services/Validation/FieldValidators.swift
import Foundation
enum FieldValidators {
    static func isValidEmail(_ s: String) -> Bool {
        let re = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return s.range(of: re, options: .regularExpression) != nil
    }
    static func isValidPassword(_ s: String) -> Bool { s.count >= 6 }
    static func isValidPhone(_ s: String) -> Bool {
        s.filter(\.isNumber).count >= 10
    }
    static func isNonEmpty(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 1.3: AuthService protocol + FakeAuthService

**Files:**
- Create: `SushiGarden/Services/Auth/AuthService.swift`
- Create: `SushiGarden/Services/Auth/FakeAuthService.swift`
- Test: `SushiGardenTests/Services/FakeAuthServiceTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Services/FakeAuthServiceTests.swift
import XCTest
@testable import SushiGarden

final class FakeAuthServiceTests: XCTestCase {
    func test_signUp_setsCurrentUser() async throws {
        let svc = FakeAuthService()
        let user = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Саша")
        XCTAssertEqual(user.email, "a@b.ru")
        XCTAssertEqual(svc.currentUser?.name, "Саша")
    }
    func test_signIn_failsForUnknownWhenConfigured() async {
        let svc = FakeAuthService(shouldFail: true)
        do { _ = try await svc.signIn(email: "x@y.ru", password: "123456"); XCTFail("expected throw") }
        catch { XCTAssertTrue(error is AuthError) }
    }
    func test_signOut_clearsUser() async throws {
        let svc = FakeAuthService()
        _ = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Саша")
        try svc.signOut()
        XCTAssertNil(svc.currentUser)
    }
    func test_seededSession_startsSignedIn() {
        let svc = FakeAuthService(seeded: UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru"))
        XCTAssertNotNil(svc.currentUser)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Services/Auth/AuthService.swift
import Foundation

enum AuthError: Error, Equatable { case invalidCredentials, network, unknown(String) }

protocol AuthService: AnyObject {
    var currentUser: UserProfile? { get }
    func signUp(email: String, password: String, name: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() throws
}
```

```swift
// SushiGarden/Services/Auth/FakeAuthService.swift
import Foundation

final class FakeAuthService: AuthService {
    private(set) var currentUser: UserProfile?
    private let shouldFail: Bool
    init(seeded: UserProfile? = nil, shouldFail: Bool = false) {
        self.currentUser = seeded
        self.shouldFail = shouldFail
    }
    func signUp(email: String, password: String, name: String) async throws -> UserProfile {
        if shouldFail { throw AuthError.unknown("forced") }
        let u = UserProfile(id: UUID().uuidString, name: name, email: email)
        currentUser = u
        return u
    }
    func signIn(email: String, password: String) async throws -> UserProfile {
        if shouldFail { throw AuthError.invalidCredentials }
        let u = UserProfile(id: "u1", name: "Александр Новиков", email: email)
        currentUser = u
        return u
    }
    func signOut() throws { currentUser = nil }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 1.4: FirebaseAuthService

Wraps FirebaseAuth in async/await and maps errors. Compiles without real creds; only fails at runtime if `FirebaseApp.configure()` wasn't called (handled in AppDelegate, Task 1.6).

**Files:**
- Create: `SushiGarden/Services/Auth/FirebaseAuthService.swift`
- Test: `SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift`

- [ ] **Step 1: Failing test for error mapping (pure function, no network)**

```swift
// SushiGardenTests/Services/FirebaseAuthErrorMappingTests.swift
import XCTest
@testable import SushiGarden

final class FirebaseAuthErrorMappingTests: XCTestCase {
    func test_mapsWrongPasswordToInvalidCredentials() {
        let ns = NSError(domain: "FIRAuthErrorDomain", code: 17009) // wrong password
        XCTAssertEqual(FirebaseAuthService.map(ns), .invalidCredentials)
    }
    func test_mapsNetworkError() {
        let ns = NSError(domain: "FIRAuthErrorDomain", code: 17020) // network
        XCTAssertEqual(FirebaseAuthService.map(ns), .network)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Services/Auth/FirebaseAuthService.swift
import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthService {
    var currentUser: UserProfile? {
        Auth.auth().currentUser.map { Self.profile(from: $0) }
    }
    func signUp(email: String, password: String, name: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            return UserProfile(id: result.user.uid, name: name, email: email)
        } catch { throw Self.map(error as NSError) }
    }
    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.profile(from: result.user)
        } catch { throw Self.map(error as NSError) }
    }
    func signOut() throws { try Auth.auth().signOut() }

    static func profile(from u: User) -> UserProfile {
        UserProfile(id: u.uid, name: u.displayName ?? "", email: u.email ?? "")
    }
    static func map(_ e: NSError) -> AuthError {
        switch e.code {
        case 17009, 17011, 17004: return .invalidCredentials
        case 17020: return .network
        default: return .unknown("\(e.code)")
        }
    }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 1.5: Dependencies (DI container)

**Files:**
- Create: `SushiGarden/App/Dependencies.swift`
- Test: `SushiGardenTests/App/DependenciesTests.swift`

- [ ] **Step 1: Failing test**

```swift
// SushiGardenTests/App/DependenciesTests.swift
import XCTest
@testable import SushiGarden

final class DependenciesTests: XCTestCase {
    func test_uiTestFlag_usesFakeAuth() {
        let deps = Dependencies(launchArguments: ["-UITEST"])
        XCTAssertTrue(deps.auth is FakeAuthService)
    }
    func test_default_usesFirebaseAuth() {
        let deps = Dependencies(launchArguments: [])
        XCTAssertTrue(deps.auth is FirebaseAuthService)
    }
    func test_uiTest_seedsSignedInUserWhenRequested() {
        let deps = Dependencies(launchArguments: ["-UITEST", "-SEEDED_AUTH"])
        XCTAssertNotNil(deps.auth.currentUser)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/App/Dependencies.swift
import Foundation

final class Dependencies {
    let auth: AuthService
    let menu: MenuRepository
    let cart: CartService
    let orders: OrderStore
    let isUITest: Bool

    init(launchArguments: [String] = ProcessInfo.processInfo.arguments,
         menu: MenuRepository = MenuRepository(),
         cart: CartService = CartService(),
         orders: OrderStore? = nil) {
        let uiTest = launchArguments.contains("-UITEST")
        self.isUITest = uiTest
        if uiTest {
            let seeded = launchArguments.contains("-SEEDED_AUTH")
                ? UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru") : nil
            self.auth = FakeAuthService(seeded: seeded)
        } else {
            self.auth = FirebaseAuthService()
        }
        self.menu = menu
        self.cart = cart
        self.orders = orders ?? OrderStore(inMemory: uiTest)
    }
}
```
> `MenuRepository`, `CartService`, and `OrderStore` are created in Phases 2–3. To keep this task green now, add **temporary stub types** in the same file marked with `// TEMP-STUB: replaced in Task 2.x/3.x`, each an empty `final class` with the initializer signature used above. They are deleted when the real types land. (This is a deliberate compile bridge, not a feature placeholder.)

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 1.6: AppDelegate configures Firebase + fonts

**Files:**
- Modify: `SushiGarden/App/AppDelegate.swift`
- Create: `SushiGarden/App/GoogleService-Info.plist` (stub, git-ignored) — see step note

- [ ] **Step 1: Implement AppDelegate**

```swift
// SushiGarden/App/AppDelegate.swift
import UIKit
import FirebaseCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FontLoader.registerAll()
        let isUITest = ProcessInfo.processInfo.arguments.contains("-UITEST")
        // Only configure Firebase when a real plist is present and not under UI tests.
        if !isUITest, Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        }
        return true
    }
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
```

> **User dependency:** the real `GoogleService-Info.plist` goes in `SushiGarden/App/` (git-ignored). Add it to `project.yml` sources implicitly (it's under `SushiGarden`). Until provided, Firebase is skipped and the app still runs (real sign-in returns `.unknown` until creds exist; use `-UITEST` for development of downstream screens).

- [ ] **Step 2: Regenerate, build, run smoke UI test, commit**

```bash
xcodegen generate
xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:SushiGardenUITests/UISmokePlaceholderTests 2>&1 | tail -10
git add -A && git commit -m "Configure Firebase + fonts in AppDelegate

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 1.7: AuthViewModel

**Files:**
- Create: `SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift`
- Test: `SushiGardenTests/Features/AuthViewModelTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Features/AuthViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class AuthViewModelTests: XCTestCase {
    func test_registerDisabled_untilValidAndConsent() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
        vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
        XCTAssertFalse(vm.canSubmit)        // consent off
        vm.consent = true
        XCTAssertTrue(vm.canSubmit)
    }
    func test_loginDisabled_untilValid() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .login)
        vm.email = "a@b.ru"; vm.password = "12345"
        XCTAssertFalse(vm.canSubmit)
        vm.password = "123456"
        XCTAssertTrue(vm.canSubmit)
    }
    func test_submit_success_setsAuthenticated() async {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .login)
        vm.email = "a@b.ru"; vm.password = "123456"
        await vm.submit()
        if case .authenticated = vm.state {} else { XCTFail("expected authenticated") }
    }
    func test_submit_failure_setsError() async {
        let vm = AuthViewModel(auth: FakeAuthService(shouldFail: true), mode: .login)
        vm.email = "a@b.ru"; vm.password = "123456"
        await vm.submit()
        if case .error = vm.state {} else { XCTFail("expected error") }
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Auth/ViewModel/AuthViewModel.swift
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode { case register, login }
    enum State: Equatable { case idle, loading, authenticated(UserProfile), error(String) }

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var consent = false
    @Published private(set) var state: State = .idle
    @Published var mode: Mode

    private let auth: AuthService
    init(auth: AuthService, mode: Mode) { self.auth = auth; self.mode = mode }

    var canSubmit: Bool {
        let base = FieldValidators.isValidEmail(email) && FieldValidators.isValidPassword(password)
        switch mode {
        case .login: return base
        case .register: return base && FieldValidators.isNonEmpty(name) && consent
        }
    }

    func toggleMode() { mode = (mode == .login) ? .register : .login; state = .idle }

    func submit() async {
        guard canSubmit else { return }
        state = .loading
        do {
            let user: UserProfile = (mode == .register)
                ? try await auth.signUp(email: email, password: password, name: name)
                : try await auth.signIn(email: email, password: password)
            state = .authenticated(user)
        } catch let e as AuthError {
            state = .error(Self.message(e))
        } catch {
            state = .error("Что-то пошло не так")
        }
    }

    private static func message(_ e: AuthError) -> String {
        switch e {
        case .invalidCredentials: return "Неверная почта или пароль"
        case .network: return "Нет соединения"
        case .unknown: return "Что-то пошло не так"
        }
    }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 1.8: Auth views (Register + Login) + RootTabBarController + routing

**Files:**
- Create: `SushiGarden/Features/Auth/View/RegisterView.swift`
- Create: `SushiGarden/Features/Auth/View/LoginView.swift`
- Create: `SushiGarden/Features/Auth/View/AuthContainerView.swift`
- Create: `SushiGarden/App/RootTabBarController.swift`
- Modify: `SushiGarden/App/SceneDelegate.swift`
- Test: `SushiGardenUITests/AuthFlowUITests.swift`

- [ ] **Step 1: Failing UI test**

```swift
// SushiGardenUITests/AuthFlowUITests.swift
import XCTest
final class AuthFlowUITests: XCTestCase {
    func test_register_thenLandsOnCatalogTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST"]   // FakeAuth, not seeded -> starts on Auth
        app.launch()
        app.textFields["auth.name"].tap();     app.typeText("Саша")
        app.textFields["auth.email"].tap();    app.typeText("a@b.ru")
        app.secureTextFields["auth.password"].tap(); app.typeText("123456")
        app.switches["auth.consent"].tap()
        app.buttons["auth.submit"].tap()
        XCTAssertTrue(app.otherElements["tabbar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab.catalog"].exists)
    }
    func test_toggleToLogin() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST"]
        app.launch()
        app.buttons["auth.toggleMode"].tap()
        XCTAssertTrue(app.staticTexts["Войти"].exists)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement views**

```swift
// SushiGarden/Features/Auth/View/AuthContainerView.swift
import SwiftUI

struct AuthContainerView: View {
    @StateObject var vm: AuthViewModel
    var onAuthenticated: (UserProfile) -> Void

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Text(vm.mode == .register ? Strings.Auth.register : Strings.Auth.login)
                    .font(AppFont.sen(24, bold: true)).foregroundStyle(AppColor.textPrimary)
                if vm.mode == .register {
                    field(Strings.Auth.name, text: $vm.name, id: A11y.Auth.nameField)
                }
                field(Strings.Auth.email, text: $vm.email, id: A11y.Auth.emailField, keyboard: .emailAddress)
                secureField(Strings.Auth.password, text: $vm.password, id: A11y.Auth.passwordField)
                if vm.mode == .register {
                    Toggle(Strings.Auth.consent, isOn: $vm.consent)
                        .font(AppFont.sen(12)).foregroundStyle(AppColor.textSecondary)
                        .accessibilityIdentifier(A11y.Auth.consentToggle)
                }
                Button(action: { Task { await vm.submit() } }) {
                    Text(vm.mode == .register ? Strings.Auth.register : Strings.Auth.login)
                        .font(AppFont.sectionHeader).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canSubmit)
                .accessibilityIdentifier(A11y.Auth.submit)

                Button(vm.mode == .register ? Strings.Auth.haveAccount : Strings.Auth.noAccount) {
                    vm.toggleMode()
                }
                .font(AppFont.sen(13)).foregroundStyle(AppColor.accent)
                .accessibilityIdentifier(A11y.Auth.toggleMode)

                if case let .error(msg) = vm.state {
                    Text(msg).font(AppFont.sen(12)).foregroundStyle(AppColor.accent)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .onChange(of: vm.state) { _, new in
            if case let .authenticated(user) = new { onAuthenticated(user) }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, id: String,
                       keyboard: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(AppColor.textSecondary))
            .keyboardType(keyboard).autocorrectionDisabled().textInputAutocapitalization(.never)
            .padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }
    private func secureField(_ placeholder: String, text: Binding<String>, id: String) -> some View {
        SecureField("", text: text, prompt: Text(placeholder).foregroundColor(AppColor.textSecondary))
            .padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }
}
```

> `RegisterView.swift` and `LoginView.swift` are thin wrappers constructing `AuthContainerView` with the matching `mode`, kept as separate files for navigation clarity:
```swift
// SushiGarden/Features/Auth/View/RegisterView.swift
import SwiftUI
struct RegisterView: View {
    let deps: Dependencies; let onAuthenticated: (UserProfile) -> Void
    var body: some View {
        AuthContainerView(vm: AuthViewModel(auth: deps.auth, mode: .register),
                          onAuthenticated: onAuthenticated)
    }
}
```
```swift
// SushiGarden/Features/Auth/View/LoginView.swift
import SwiftUI
struct LoginView: View {
    let deps: Dependencies; let onAuthenticated: (UserProfile) -> Void
    var body: some View {
        AuthContainerView(vm: AuthViewModel(auth: deps.auth, mode: .login),
                          onAuthenticated: onAuthenticated)
    }
}
```

- [ ] **Step 4: Implement RootTabBarController**

```swift
// SushiGarden/App/RootTabBarController.swift
import UIKit
import SwiftUI

final class RootTabBarController: UITabBarController {
    init(deps: Dependencies, user: UserProfile, onLogout: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        view.accessibilityIdentifier = A11y.Tabs.bar

        func tab<V: View>(_ view: V, title: String, system: String, id: String) -> UIViewController {
            let host = UIHostingController(rootView: view)
            host.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: system), tag: 0)
            host.tabBarItem.accessibilityIdentifier = id
            return host
        }
        // Real feature views are wired as they are built (Phases 2–5).
        viewControllers = [
            tab(CatalogView(deps: deps), title: Strings.Tabs.catalog, system: "square.grid.2x2", id: A11y.Tabs.catalog),
            tab(PromotionsView(deps: deps), title: Strings.Tabs.promotions, system: "tag", id: A11y.Tabs.promotions),
            tab(OrdersView(deps: deps), title: Strings.Tabs.orders, system: "clock", id: A11y.Tabs.orders),
            tab(CartView(deps: deps), title: Strings.Tabs.cart, system: "bag", id: A11y.Tabs.cart),
            tab(ProfileView(deps: deps, user: user, onLogout: onLogout), title: Strings.Tabs.profile, system: "person", id: A11y.Tabs.profile),
        ]
        tabBar.barTintColor = UIColor(AppColor.tabBar)
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor(AppColor.inactive)
    }
    required init?(coder: NSCoder) { fatalError() }
}
```
> `CatalogView`, `PromotionsView`, `OrdersView`, `CartView`, `ProfileView` are built in later phases. To compile now, add **temporary stub views** (one-line `Text("…")` views taking `deps:`) in their target files, replaced by the real implementations in their tasks. Mark each `// TEMP-STUB`.

- [ ] **Step 5: Routing in SceneDelegate**

```swift
// SushiGarden/App/SceneDelegate.swift
import UIKit
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private lazy var deps = Dependencies()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        if let user = deps.auth.currentUser {
            showMain(user)
        } else {
            showAuth()
        }
        window.makeKeyAndVisible()
    }

    private func showAuth() {
        let root = UIHostingController(
            rootView: RegisterView(deps: deps) { [weak self] user in self?.showMain(user) }
        )
        window?.rootViewController = root
    }
    private func showMain(_ user: UserProfile) {
        window?.rootViewController = RootTabBarController(deps: deps, user: user) { [weak self] in
            try? self?.deps.auth.signOut()
            self?.showAuth()
        }
    }
}
```

- [ ] **Step 6: Regenerate, run the auth UI tests, commit**

```bash
xcodegen generate
xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:SushiGardenUITests/AuthFlowUITests 2>&1 | tail -15
git add -A && git commit -m "Add auth screens, tab bar shell, and routing

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

# Phase 2 — Catalog, Product Detail, Cart service

### Task 2.1: Domain models — Category, Product, AddOn, CartItem

**Files:**
- Create: `SushiGarden/SharedModels/Category.swift`, `Product.swift`, `AddOn.swift`, `CartItem.swift`
- Test: `SushiGardenTests/SharedModels/CatalogModelsTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/SharedModels/CatalogModelsTests.swift
import XCTest
@testable import SushiGarden

final class CatalogModelsTests: XCTestCase {
    func test_product_fields() {
        let p = Product(id: "hikari", name: "Хикари", category: .rolls,
                        priceRub: 620, weightGrams: 255, imageName: "product_hikari",
                        description: "Описание")
        XCTAssertEqual(p.priceRub, 620)
        XCTAssertEqual(p.category, .rolls)
    }
    func test_cartItem_lineTotal() {
        let p = Product(id: "x", name: "X", category: .rolls, priceRub: 100,
                        weightGrams: 10, imageName: "i", description: "")
        let item = CartItem(product: p, quantity: 3)
        XCTAssertEqual(item.lineTotal, 300)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/SharedModels/Category.swift
enum Category: String, CaseIterable, Identifiable {
    case sushi, rolls, hotRolls, salads, wok
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sushi: return "Суши"; case .rolls: return "Роллы"
        case .hotRolls: return "Горячие роллы"; case .salads: return "Салаты"
        case .wok: return "WOK"
        }
    }
}
```
```swift
// SushiGarden/SharedModels/Product.swift
struct Product: Identifiable, Equatable {
    let id: String
    let name: String
    let category: Category
    let priceRub: Int
    let weightGrams: Int
    let imageName: String
    let description: String
}
```
```swift
// SushiGarden/SharedModels/AddOn.swift
struct AddOn: Identifiable, Equatable {
    let id: String
    let name: String
    let priceRub: Int
}
```
```swift
// SushiGarden/SharedModels/CartItem.swift
struct CartItem: Identifiable, Equatable {
    let product: Product
    var quantity: Int
    var id: String { product.id }
    var lineTotal: Int { product.priceRub * quantity }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 2.2: MenuRepository (mock data from Figma)

**Files:**
- Create: `SushiGarden/Services/Catalog/MenuRepository.swift` (replaces the TEMP-STUB)
- Test: `SushiGardenTests/Services/MenuRepositoryTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Services/MenuRepositoryTests.swift
import XCTest
@testable import SushiGarden

final class MenuRepositoryTests: XCTestCase {
    func test_allCategoriesHaveItems() {
        let repo = MenuRepository()
        for c in Category.allCases {
            XCTAssertFalse(repo.products(in: c).isEmpty, "\(c.title) empty")
        }
    }
    func test_knownFigmaItemExists() {
        let repo = MenuRepository()
        let hikari = repo.allProducts.first { $0.id == "hikari" }
        XCTAssertEqual(hikari?.priceRub, 620)
        XCTAssertEqual(hikari?.weightGrams, 255)
    }
    func test_addOnsPresent() {
        XCTAssertEqual(MenuRepository().addOns.count, 3)
        XCTAssertTrue(MenuRepository().addOns.allSatisfy { $0.priceRub == 60 })
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement** (extend with more items per category; the four below come straight from the Figma, the rest reuse the same images as placeholders)

```swift
// SushiGarden/Services/Catalog/MenuRepository.swift
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
        // Placeholder items so every category is populated; images reused.
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
```
> Delete the `MenuRepository` TEMP-STUB from `Dependencies.swift` (it's now real).

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 2.3: CartService (in-memory, observable)

**Files:**
- Create: `SushiGarden/Services/Cart/CartService.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Services/CartServiceTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Services/CartServiceTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class CartServiceTests: XCTestCase {
    private func product(_ id: String, _ price: Int) -> Product {
        Product(id: id, name: id, category: .rolls, priceRub: price,
                weightGrams: 1, imageName: "i", description: "")
    }
    func test_add_increasesQuantity() {
        let c = CartService()
        c.add(product("a", 100))
        c.add(product("a", 100))
        XCTAssertEqual(c.items.first?.quantity, 2)
    }
    func test_remove_decrementsAndDrops() {
        let c = CartService()
        c.add(product("a", 100))
        c.decrement(productID: "a")
        XCTAssertTrue(c.items.isEmpty)
    }
    func test_subtotal_andAddOns() {
        let c = CartService()
        c.add(product("a", 100)); c.setQuantity(productID: "a", to: 2) // 200
        c.toggleAddOn(AddOn(id: "wasabi", name: "Васаби", priceRub: 60))
        XCTAssertEqual(c.subtotal, 200)
        XCTAssertEqual(c.addOnsTotal, 60)
        XCTAssertEqual(c.itemCount, 2)
    }
    func test_clear() {
        let c = CartService(); c.add(product("a", 100)); c.clear()
        XCTAssertTrue(c.items.isEmpty); XCTAssertTrue(c.selectedAddOns.isEmpty)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Services/Cart/CartService.swift
import Foundation

@MainActor
final class CartService: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var selectedAddOns: [AddOn] = []

    func add(_ product: Product) {
        if let i = items.firstIndex(where: { $0.id == product.id }) {
            items[i].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }
    func decrement(productID: String) {
        guard let i = items.firstIndex(where: { $0.id == productID }) else { return }
        items[i].quantity -= 1
        if items[i].quantity <= 0 { items.remove(at: i) }
    }
    func setQuantity(productID: String, to qty: Int) {
        guard let i = items.firstIndex(where: { $0.id == productID }) else { return }
        if qty <= 0 { items.remove(at: i) } else { items[i].quantity = qty }
    }
    func quantity(of productID: String) -> Int {
        items.first(where: { $0.id == productID })?.quantity ?? 0
    }
    func toggleAddOn(_ addOn: AddOn) {
        if let i = selectedAddOns.firstIndex(of: addOn) { selectedAddOns.remove(at: i) }
        else { selectedAddOns.append(addOn) }
    }
    var subtotal: Int { items.reduce(0) { $0 + $1.lineTotal } }
    var addOnsTotal: Int { selectedAddOns.reduce(0) { $0 + $1.priceRub } }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    func clear() { items = []; selectedAddOns = [] }
}
```
> Delete the `CartService` TEMP-STUB from `Dependencies.swift`.

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 2.4: CatalogViewModel

**Files:**
- Create: `SushiGarden/Features/Catalog/ViewModel/CatalogViewModel.swift`
- Test: `SushiGardenTests/Features/CatalogViewModelTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Features/CatalogViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class CatalogViewModelTests: XCTestCase {
    func test_defaultsToRollsSelected() {
        let vm = CatalogViewModel(menu: MenuRepository(), cart: CartService())
        XCTAssertEqual(vm.selectedCategory, .rolls)
        XCTAssertFalse(vm.visibleProducts.isEmpty)
    }
    func test_selectingCategoryFiltersProducts() {
        let vm = CatalogViewModel(menu: MenuRepository(), cart: CartService())
        vm.select(.wok)
        XCTAssertTrue(vm.visibleProducts.allSatisfy { $0.category == .wok })
    }
    func test_addToCart_delegatesToService() {
        let cart = CartService()
        let vm = CatalogViewModel(menu: MenuRepository(), cart: cart)
        let p = vm.visibleProducts[0]
        vm.add(p)
        XCTAssertEqual(cart.quantity(of: p.id), 1)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Catalog/ViewModel/CatalogViewModel.swift
import Foundation

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var selectedCategory: Category = .rolls
    private let menu: MenuRepository
    private let cart: CartService
    init(menu: MenuRepository, cart: CartService) { self.menu = menu; self.cart = cart }

    var categories: [Category] { Category.allCases }
    var visibleProducts: [Product] { menu.products(in: selectedCategory) }
    func select(_ c: Category) { selectedCategory = c }
    func add(_ p: Product) { cart.add(p) }
    func quantity(of p: Product) -> Int { cart.quantity(of: p.id) }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 2.5: CatalogView + ProductCardView (replaces TEMP-STUB)

**Files:**
- Create: `SushiGarden/Features/Catalog/View/CatalogView.swift`, `ProductCardView.swift`
- Test: `SushiGardenUITests/CatalogUITests.swift`

- [ ] **Step 1: Failing UI test**

```swift
// SushiGardenUITests/CatalogUITests.swift
import XCTest
final class CatalogUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]   // start signed-in on tab bar
        app.launch(); return app
    }
    func test_catalogShowsCardsAndSwitchesCategory() {
        let app = launch()
        app.buttons["tab.catalog"].tap()
        XCTAssertTrue(app.otherElements["catalog.grid"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["catalog.card.hikari"].exists)
        app.buttons["catalog.category.WOK"].tap()
        XCTAssertTrue(app.buttons["catalog.card.wok_udon"].waitForExistence(timeout: 3))
    }
    func test_addToCartFromCard_updatesCartBadgeFlow() {
        let app = launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.hikari"].tap()           // opens detail
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement views**

```swift
// SushiGarden/Features/Catalog/View/ProductCardView.swift
import SwiftUI

struct ProductCardView: View {
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(product.imageName).resizable().scaledToFill()
                .frame(height: 150).clipped()
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCorner))
            Text(product.name).font(AppFont.productTitle).foregroundStyle(AppColor.textPrimary)
            Text("\(product.weightGrams) \(Strings.gram)")
                .font(AppFont.weight).foregroundStyle(AppColor.textSecondary)
            Text("\(product.priceRub) \(Strings.currency)")
                .font(AppFont.price).foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.pricePill)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCorner))
        }
    }
}
```

```swift
// SushiGarden/Features/Catalog/View/CatalogView.swift
import SwiftUI

struct CatalogView: View {
    let deps: Dependencies
    @StateObject private var vm: CatalogViewModel
    @State private var selected: Product?

    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: CatalogViewModel(menu: deps.menu, cart: deps.cart))
    }

    private let columns = [GridItem(.flexible(), spacing: Spacing.md),
                           GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                ScrollView {
                    categoryBar
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(vm.visibleProducts) { p in
                            Button { selected = p } label: { ProductCardView(product: p) }
                                .accessibilityIdentifier(A11y.Catalog.card(p.id))
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                    .accessibilityIdentifier(A11y.Catalog.grid)
                }
            }
            .navigationDestination(item: $selected) { p in
                ProductDetailView(product: p, cart: deps.cart)
            }
        }
        .tint(AppColor.accent)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(vm.categories) { c in
                    Button(c.title) { vm.select(c) }
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(c == vm.selectedCategory ? AppColor.textPrimary : AppColor.inactive)
                        .accessibilityIdentifier(A11y.Catalog.category(c.title))
                }
            }
            .padding(.horizontal, Spacing.screenMargin).padding(.vertical, Spacing.sm)
        }
    }
}
```
> Delete the `CatalogView` TEMP-STUB. `ProductDetailView` is built in Task 2.6 — add its TEMP-STUB now if not present so this compiles.

- [ ] **Step 4: Run, confirm catalog assertions pass** (the add-to-cart test needs Task 2.6). Commit.

```bash
xcodegen generate
xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:SushiGardenUITests/CatalogUITests/test_catalogShowsCardsAndSwitchesCategory 2>&1 | tail -15
git add -A && git commit -m "Add catalog grid, category bar, and product card

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2.6: ProductDetail (ViewModel + View)

**Files:**
- Create: `SushiGarden/Features/ProductDetail/ViewModel/ProductDetailViewModel.swift`
- Create: `SushiGarden/Features/ProductDetail/View/ProductDetailView.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Features/ProductDetailViewModelTests.swift`

- [ ] **Step 1: Failing unit tests**

```swift
// SushiGardenTests/Features/ProductDetailViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    private let p = Product(id: "hikari", name: "Хикари", category: .rolls, priceRub: 620,
                            weightGrams: 255, imageName: "product_hikari", description: "d")
    func test_quantityStartsAtOne_andSteps() {
        let vm = ProductDetailViewModel(product: p, cart: CartService())
        XCTAssertEqual(vm.quantity, 1)
        vm.increment(); XCTAssertEqual(vm.quantity, 2)
        vm.decrement(); vm.decrement(); XCTAssertEqual(vm.quantity, 1) // floor at 1
    }
    func test_addToCart_addsQuantity() {
        let cart = CartService()
        let vm = ProductDetailViewModel(product: p, cart: cart)
        vm.increment()       // qty 2
        vm.addToCart()
        XCTAssertEqual(cart.quantity(of: "hikari"), 2)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
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
```

```swift
// SushiGarden/Features/ProductDetail/View/ProductDetailView.swift
import SwiftUI

struct ProductDetailView: View {
    @StateObject private var vm: ProductDetailViewModel
    init(product: Product, cart: CartService) {
        _vm = StateObject(wrappedValue: ProductDetailViewModel(product: product, cart: cart))
    }
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(vm.product.imageName).resizable().scaledToFit()
                    .frame(maxHeight: 280)
                Text(vm.product.name).font(AppFont.sen(22, bold: true)).foregroundStyle(.white)
                Text("\(vm.product.weightGrams) \(Strings.gram)")
                    .font(AppFont.weight).foregroundStyle(AppColor.textSecondary)
                Text(vm.product.description).font(AppFont.sen(14))
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.lg)
                stepper
                Button { vm.addToCart() } label: {
                    Text("\(Strings.Cart.checkout) · \(vm.product.priceRub * vm.quantity) \(Strings.currency)")
                        .font(AppFont.sectionHeader).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, Spacing.screenMargin)
                .accessibilityIdentifier(A11y.Detail.addToCart)
            }
        }
    }
    private var stepper: some View {
        HStack(spacing: Spacing.lg) {
            Button { vm.decrement() } label: { Text("−").font(AppFont.mugesta(24)) }
                .accessibilityIdentifier(A11y.Detail.stepperMinus)
            Text("\(vm.quantity)").font(AppFont.price).foregroundStyle(.white)
                .accessibilityIdentifier(A11y.Detail.quantity)
            Button { vm.increment() } label: { Text("+").font(AppFont.mugesta(24)) }
                .accessibilityIdentifier(A11y.Detail.stepperPlus)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.sm)
        .background(AppColor.pricePill).clipShape(Capsule())
    }
}
```
> Delete the `ProductDetailView` TEMP-STUB.

- [ ] **Step 4: Run unit + the full CatalogUITests (add-to-cart now works). Step 5: Commit.**

---

# Phase 3 — Cart, Checkout, Orders persistence

### Task 3.1: Order model + OrderStore (SwiftData)

**Files:**
- Create: `SushiGarden/SharedModels/Order.swift`
- Create: `SushiGarden/Services/Orders/OrderStore.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Services/OrderStoreTests.swift`

- [ ] **Step 1: Failing tests (in-memory SwiftData)**

```swift
// SushiGardenTests/Services/OrderStoreTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class OrderStoreTests: XCTestCase {
    func test_saveAndList() throws {
        let store = OrderStore(inMemory: true)
        let order = Order(id: "o1", createdAt: .init(timeIntervalSince1970: 0),
                          totalRub: 1699,
                          lines: [OrderLine(name: "Хикари", quantity: 2, priceRub: 620)])
        try store.save(order)
        let all = try store.allOrders()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.totalRub, 1699)
        XCTAssertEqual(all.first?.lines.count, 1)
    }
    func test_ordersSortedNewestFirst() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "a", createdAt: .init(timeIntervalSince1970: 1), totalRub: 1, lines: []))
        try store.save(Order(id: "b", createdAt: .init(timeIntervalSince1970: 2), totalRub: 2, lines: []))
        XCTAssertEqual(try store.allOrders().first?.id, "b")
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/SharedModels/Order.swift
import Foundation
import SwiftData

@Model
final class OrderEntity {
    @Attribute(.unique) var id: String
    var createdAt: Date
    var totalRub: Int
    var linesData: Data           // encoded [OrderLine]
    init(id: String, createdAt: Date, totalRub: Int, linesData: Data) {
        self.id = id; self.createdAt = createdAt; self.totalRub = totalRub; self.linesData = linesData
    }
}

struct OrderLine: Codable, Equatable {
    let name: String
    let quantity: Int
    let priceRub: Int
}

struct Order: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    let totalRub: Int
    let lines: [OrderLine]
}
```

```swift
// SushiGarden/Services/Orders/OrderStore.swift
import Foundation
import SwiftData

@MainActor
final class OrderStore {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false) {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        // Force-try is acceptable: a failed local store is unrecoverable and should crash early.
        container = try! ModelContainer(for: OrderEntity.self, configurations: config)
    }

    func save(_ order: Order) throws {
        let data = try JSONEncoder().encode(order.lines)
        context.insert(OrderEntity(id: order.id, createdAt: order.createdAt,
                                   totalRub: order.totalRub, linesData: data))
        try context.save()
    }

    func allOrders() throws -> [Order] {
        let descriptor = FetchDescriptor<OrderEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).map { e in
            let lines = (try? JSONDecoder().decode([OrderLine].self, from: e.linesData)) ?? []
            return Order(id: e.id, createdAt: e.createdAt, totalRub: e.totalRub, lines: lines)
        }
    }
}
```
> Delete the `OrderStore` TEMP-STUB. Update `Dependencies` to construct `OrderStore(inMemory: uiTest)` (already wired in Task 1.5).

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 3.2: CartViewModel

**Files:**
- Create: `SushiGarden/Features/Cart/ViewModel/CartViewModel.swift`
- Test: `SushiGardenTests/Features/CartViewModelTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Features/CartViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class CartViewModelTests: XCTestCase {
    private func seededCart() -> CartService {
        let c = CartService()
        c.add(Product(id: "la", name: "Лос-Анджелес", category: .rolls, priceRub: 707,
                      weightGrams: 285, imageName: "product_la", description: ""))
        return c
    }
    func test_exposesItemsAndTotals() {
        let vm = CartViewModel(cart: seededCart(), menu: MenuRepository())
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.subtotal, 707)
        XCTAssertEqual(vm.addOns.count, 3)
    }
    func test_incrementDecrement() {
        let cart = seededCart()
        let vm = CartViewModel(cart: cart, menu: MenuRepository())
        vm.increment(vm.items[0])
        XCTAssertEqual(cart.quantity(of: "la"), 2)
        vm.decrement(vm.items[0]); vm.decrement(cart.items[0])
        XCTAssertTrue(cart.items.isEmpty)
    }
    func test_grandTotal_includesAddOns() {
        let cart = seededCart()
        let vm = CartViewModel(cart: cart, menu: MenuRepository())
        vm.toggle(MenuRepository().addOns[0])     // +60
        XCTAssertEqual(vm.grandTotal, 767)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Cart/ViewModel/CartViewModel.swift
import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var selectedAddOns: [AddOn] = []
    let addOns: [AddOn]
    private let cart: CartService
    private var bag = Set<AnyCancellable>()

    init(cart: CartService, menu: MenuRepository) {
        self.cart = cart
        self.addOns = menu.addOns
        cart.$items.assign(to: &$items)
        cart.$selectedAddOns.assign(to: &$selectedAddOns)
    }
    func increment(_ item: CartItem) { cart.add(item.product) }
    func decrement(_ item: CartItem) { cart.decrement(productID: item.id) }
    func toggle(_ addOn: AddOn) { cart.toggleAddOn(addOn) }
    func isSelected(_ addOn: AddOn) -> Bool { selectedAddOns.contains(addOn) }
    var subtotal: Int { cart.subtotal }
    var addOnsTotal: Int { cart.addOnsTotal }
    var grandTotal: Int { cart.subtotal + cart.addOnsTotal }
    var isEmpty: Bool { items.isEmpty }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 3.3: CartView (replaces TEMP-STUB)

**Files:**
- Create: `SushiGarden/Features/Cart/View/CartView.swift`
- Test: `SushiGardenUITests/CartUITests.swift`

- [ ] **Step 1: Failing UI test**

```swift
// SushiGardenUITests/CartUITests.swift
import XCTest
final class CartUITests: XCTestCase {
    func test_addItem_thenSeeItInCart_andCheckoutEnabled() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Лос-Анджелес"].exists)
        XCTAssertTrue(app.buttons["cart.checkout"].isEnabled)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Cart/View/CartView.swift
import SwiftUI

struct CartView: View {
    let deps: Dependencies
    @StateObject private var vm: CartViewModel
    @State private var goCheckout = false

    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: CartViewModel(cart: deps.cart, menu: deps.menu))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            ForEach(vm.items) { item in row(item) }
                            addOnsSection
                        }
                        .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
                    }
                    .accessibilityIdentifier(A11y.Cart.list)
                    checkoutBar
                }
            }
            .navigationTitle(Strings.Tabs.cart)
            .navigationDestination(isPresented: $goCheckout) {
                CheckoutView(deps: deps, total: vm.grandTotal)
            }
        }
        .tint(AppColor.accent)
    }

    private func row(_ item: CartItem) -> some View {
        HStack {
            Image(item.product.imageName).resizable().scaledToFill()
                .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(item.product.name).font(AppFont.productTitle).foregroundStyle(.white)
                Text("\(item.lineTotal) \(Strings.currency)").font(AppFont.weight)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.md) {
                Button("−") { vm.decrement(item) }.font(AppFont.mugesta(20))
                Text("\(item.quantity)").foregroundStyle(.white)
                Button("+") { vm.increment(item) }.font(AppFont.mugesta(20))
            }.foregroundStyle(.white)
        }
    }

    private var addOnsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.Cart.addMore).font(AppFont.sectionHeader).foregroundStyle(.white)
            ForEach(vm.addOns) { a in
                Button { vm.toggle(a) } label: {
                    HStack {
                        Image(systemName: vm.isSelected(a) ? "checkmark.circle.fill" : "circle")
                        Text(a.name).foregroundStyle(.white)
                        Spacer()
                        Text("\(a.priceRub) \(Strings.currency)").foregroundStyle(AppColor.textSecondary)
                    }
                }
                .tint(AppColor.accent)
                .accessibilityIdentifier(A11y.Cart.addon(a.id))
            }
        }
    }

    private var checkoutBar: some View {
        Button { goCheckout = true } label: {
            Text("\(Strings.Cart.checkout) · \(vm.grandTotal) \(Strings.currency)")
                .font(AppFont.sectionHeader).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding()
                .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(vm.isEmpty)
        .padding(Spacing.screenMargin)
        .accessibilityIdentifier(A11y.Cart.checkout)
    }
}
```
> Delete the `CartView` TEMP-STUB. `CheckoutView` TEMP-STUB must exist to compile (built in Task 3.4).

- [ ] **Step 4: Run UI test pass. Step 5: Commit.**

---

### Task 3.4: CheckoutViewModel + CheckoutView

**Files:**
- Create: `SushiGarden/Features/Checkout/ViewModel/CheckoutViewModel.swift`
- Create: `SushiGarden/Features/Checkout/View/CheckoutView.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Features/CheckoutViewModelTests.swift`, `SushiGardenUITests/CheckoutUITests.swift`

- [ ] **Step 1: Failing unit tests**

```swift
// SushiGardenTests/Features/CheckoutViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class CheckoutViewModelTests: XCTestCase {
    private func filledCart() -> CartService {
        let c = CartService()
        c.add(Product(id: "la", name: "Лос-Анджелес", category: .rolls, priceRub: 707,
                      weightGrams: 285, imageName: "product_la", description: ""))
        return c
    }
    func test_summaryMath() {
        let vm = CheckoutViewModel(cart: filledCart(), orders: OrderStore(inMemory: true))
        XCTAssertEqual(vm.subtotal, 707)
        XCTAssertEqual(vm.deliveryFee, 76)
        XCTAssertEqual(vm.serviceFee, 76)         // defined constant; see impl
        XCTAssertEqual(vm.total, 707 + 76 + 76)
    }
    func test_confirmDisabled_untilContactValid() {
        let vm = CheckoutViewModel(cart: filledCart(), orders: OrderStore(inMemory: true))
        XCTAssertFalse(vm.canConfirm)
        vm.name = "Саша"; vm.phone = "+7 900 123 45 67"; vm.email = "a@b.ru"
        XCTAssertTrue(vm.canConfirm)
    }
    func test_confirm_persistsOrder_andClearsCart() async throws {
        let cart = filledCart()
        let store = OrderStore(inMemory: true)
        let vm = CheckoutViewModel(cart: cart, orders: store)
        vm.name = "Саша"; vm.phone = "+7 900 123 45 67"; vm.email = "a@b.ru"
        await vm.confirm()
        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertEqual(try store.allOrders().count, 1)
        XCTAssertTrue(vm.didConfirm)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Checkout/ViewModel/CheckoutViewModel.swift
import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var name = ""
    @Published var phone = ""
    @Published var email = ""
    @Published private(set) var didConfirm = false

    private let cart: CartService
    private let orders: OrderStore
    init(cart: CartService, orders: OrderStore) { self.cart = cart; self.orders = orders }

    let deliveryFee = 76
    let serviceFee = 76
    var subtotal: Int { cart.subtotal + cart.addOnsTotal }
    var total: Int { subtotal + deliveryFee + serviceFee }

    var canConfirm: Bool {
        !cart.items.isEmpty
            && FieldValidators.isNonEmpty(name)
            && FieldValidators.isValidPhone(phone)
            && FieldValidators.isValidEmail(email)
    }

    func confirm() async {
        guard canConfirm else { return }
        let lines = cart.items.map { OrderLine(name: $0.product.name, quantity: $0.quantity, priceRub: $0.product.priceRub) }
        let order = Order(id: UUID().uuidString, createdAt: Date(), totalRub: total, lines: lines)
        do {
            try orders.save(order)
            cart.clear()
            didConfirm = true
        } catch { didConfirm = false }
    }
}
```

```swift
// SushiGarden/Features/Checkout/View/CheckoutView.swift
import SwiftUI

struct CheckoutView: View {
    let deps: Dependencies
    let total: Int
    @StateObject private var vm: CheckoutViewModel
    @State private var goTracking = false

    init(deps: Dependencies, total: Int) {
        self.deps = deps; self.total = total
        _vm = StateObject(wrappedValue: CheckoutViewModel(cart: deps.cart, orders: deps.orders))
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.md) {
                    field(Strings.Auth.name, $vm.name, A11y.Checkout.name)
                    field(Strings.Checkout.phone, $vm.phone, A11y.Checkout.phone, .phonePad)
                    field(Strings.Auth.email, $vm.email, A11y.Checkout.email, .emailAddress)
                    summaryRow(Strings.Cart.sum, vm.subtotal)
                    summaryRow(Strings.Cart.delivery, vm.deliveryFee)
                    summaryRow(Strings.Cart.serviceFee, vm.serviceFee)
                    summaryRow(Strings.Cart.total, vm.total, bold: true)
                    Button { Task { await vm.confirm() } } label: {
                        Text(Strings.Cart.confirm).font(AppFont.sectionHeader).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!vm.canConfirm)
                    .accessibilityIdentifier(A11y.Checkout.confirm)
                }
                .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
            }
            .navigationDestination(isPresented: $goTracking) { TrackingView(deps: deps) }
        }
        .navigationTitle(Strings.Checkout.address)
        .onChange(of: vm.didConfirm) { _, ok in if ok { goTracking = true } }
    }

    private func field(_ ph: String, _ text: Binding<String>, _ id: String,
                       _ kb: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(ph).foregroundColor(AppColor.textSecondary))
            .keyboardType(kb).padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }
    private func summaryRow(_ label: String, _ value: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text("\(value) \(Strings.currency)")
                .font(bold ? AppFont.price : AppFont.weight)
                .foregroundStyle(.white)
        }
    }
}
```
> Delete the `CheckoutView` TEMP-STUB. `TrackingView` TEMP-STUB must exist (built in Phase 5).

- [ ] **Step 4: Failing UI test, then make pass**

```swift
// SushiGardenUITests/CheckoutUITests.swift
import XCTest
final class CheckoutUITests: XCTestCase {
    func test_fullCheckoutFlow_reachesTracking() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        app.buttons["cart.checkout"].tap()
        app.textFields["checkout.name"].tap();  app.typeText("Саша")
        app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
        app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
        app.buttons["checkout.confirm"].tap()
        XCTAssertTrue(app.otherElements["tracking.map"].waitForExistence(timeout: 5))
    }
}
```
Run only after Phase 5 `TrackingView` exists; until then assert reaching `checkout.confirm`. Commit after unit tests pass.

- [ ] **Step 5: Commit.**

---

# Phase 4 — Promotions, Profile, Orders list

### Task 4.1: PromotionsViewModel + PromotionsView

**Files:**
- Create: `SushiGarden/Features/Promotions/ViewModel/PromotionsViewModel.swift`
- Create: `SushiGarden/Features/Promotions/View/PromotionsView.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Features/PromotionsViewModelTests.swift`, `SushiGardenUITests/PromotionsUITests.swift`

- [ ] **Step 1: Failing unit test**

```swift
// SushiGardenTests/Features/PromotionsViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class PromotionsViewModelTests: XCTestCase {
    func test_hasBanners() {
        let vm = PromotionsViewModel()
        XCTAssertGreaterThanOrEqual(vm.banners.count, 2)
        XCTAssertEqual(vm.banners.first?.imageName, "banner_promo_1")
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Promotions/ViewModel/PromotionsViewModel.swift
import Foundation

struct Banner: Identifiable, Equatable { let id: String; let imageName: String }

@MainActor
final class PromotionsViewModel: ObservableObject {
    let banners: [Banner] = [
        Banner(id: "b1", imageName: "banner_promo_1"),
        Banner(id: "b2", imageName: "banner_promo_2"),
    ]
}
```

```swift
// SushiGarden/Features/Promotions/View/PromotionsView.swift
import SwiftUI

struct PromotionsView: View {
    let deps: Dependencies
    @StateObject private var vm = PromotionsViewModel()
    init(deps: Dependencies) { self.deps = deps }
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(vm.banners) { b in
                            Image(b.imageName).resizable().scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.bannerCorner))
                                .accessibilityIdentifier("promo.\(b.id)")
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
                }
            }
            .navigationTitle(Strings.Tabs.promotions)
        }
        .tint(AppColor.accent)
    }
}
```
> Delete the `PromotionsView` TEMP-STUB.

- [ ] **Step 4: UI test**

```swift
// SushiGardenUITests/PromotionsUITests.swift
import XCTest
final class PromotionsUITests: XCTestCase {
    func test_showsBanners() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.promotions"].tap()
        XCTAssertTrue(app.images["promo.b1"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 5: Run pass. Commit.**

---

### Task 4.2: OrdersViewModel + OrdersView

**Files:**
- Create: `SushiGarden/Features/Orders/ViewModel/OrdersViewModel.swift`
- Create: `SushiGarden/Features/Orders/View/OrdersView.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Features/OrdersViewModelTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Features/OrdersViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class OrdersViewModelTests: XCTestCase {
    func test_loadsOrders() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "o1", createdAt: Date(), totalRub: 1699,
                             lines: [OrderLine(name: "Хикари", quantity: 1, priceRub: 620)]))
        let vm = OrdersViewModel(orders: store)
        vm.load()
        XCTAssertEqual(vm.orders.count, 1)
        XCTAssertFalse(vm.isEmpty)
    }
    func test_emptyState() {
        let vm = OrdersViewModel(orders: OrderStore(inMemory: true))
        vm.load()
        XCTAssertTrue(vm.isEmpty)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Orders/ViewModel/OrdersViewModel.swift
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []
    private let orders_store: OrderStore
    init(orders: OrderStore) { self.orders_store = orders }
    func load() { orders = (try? orders_store.allOrders()) ?? [] }
    var isEmpty: Bool { orders.isEmpty }
}
```

```swift
// SushiGarden/Features/Orders/View/OrdersView.swift
import SwiftUI

struct OrdersView: View {
    let deps: Dependencies
    @StateObject private var vm: OrdersViewModel
    init(deps: Dependencies) {
        self.deps = deps
        _vm = StateObject(wrappedValue: OrdersViewModel(orders: deps.orders))
    }
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                if vm.isEmpty {
                    Text("Заказов пока нет").foregroundStyle(AppColor.textSecondary)
                        .accessibilityIdentifier(A11y.Orders.empty)
                } else {
                    List(vm.orders) { o in
                        VStack(alignment: .leading) {
                            Text("Заказ №\(o.id.prefix(6))").font(AppFont.productTitle).foregroundStyle(.white)
                            Text("\(o.totalRub) \(Strings.currency)").foregroundStyle(AppColor.textSecondary)
                        }
                        .listRowBackground(AppColor.tabBar)
                    }
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier(A11y.Orders.list)
                }
            }
            .navigationTitle(Strings.Tabs.orders)
            .onAppear { vm.load() }
        }
        .tint(AppColor.accent)
    }
}
```
> Delete the `OrdersView` TEMP-STUB.

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 4.3: ProfileViewModel + ProfileView (with logout)

**Files:**
- Create: `SushiGarden/Features/Profile/ViewModel/ProfileViewModel.swift`
- Create: `SushiGarden/Features/Profile/View/ProfileView.swift` (replaces TEMP-STUB)
- Test: `SushiGardenTests/Features/ProfileViewModelTests.swift`, `SushiGardenUITests/ProfileUITests.swift`

- [ ] **Step 1: Failing unit test**

```swift
// SushiGardenTests/Features/ProfileViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_exposesUserAndRecentOrders() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "o1", createdAt: Date(), totalRub: 100, lines: []))
        let user = UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru")
        let vm = ProfileViewModel(user: user, orders: store)
        vm.load()
        XCTAssertEqual(vm.user.name, "Александр Новиков")
        XCTAssertEqual(vm.recentOrders.count, 1)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Profile/ViewModel/ProfileViewModel.swift
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    let user: UserProfile
    @Published private(set) var recentOrders: [Order] = []
    private let orders: OrderStore
    init(user: UserProfile, orders: OrderStore) { self.user = user; self.orders = orders }
    func load() { recentOrders = (try? orders.allOrders()) ?? [] }
}
```

```swift
// SushiGarden/Features/Profile/View/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    let deps: Dependencies
    let user: UserProfile
    let onLogout: () -> Void
    @StateObject private var vm: ProfileViewModel

    init(deps: Dependencies, user: UserProfile, onLogout: @escaping () -> Void) {
        self.deps = deps; self.user = user; self.onLogout = onLogout
        _vm = StateObject(wrappedValue: ProfileViewModel(user: user, orders: deps.orders))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "person.crop.circle.fill").resizable()
                        .frame(width: 72, height: 72).foregroundStyle(AppColor.textSecondary)
                    Text(vm.user.name).font(AppFont.sen(20, bold: true)).foregroundStyle(.white)
                        .accessibilityIdentifier(A11y.Profile.name)
                    Text(vm.user.email).foregroundStyle(AppColor.textSecondary)

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
> Delete the `ProfileView` TEMP-STUB.

- [ ] **Step 4: UI test (logout returns to auth)**

```swift
// SushiGardenUITests/ProfileUITests.swift
import XCTest
final class ProfileUITests: XCTestCase {
    func test_logout_returnsToAuth() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.profile"].tap()
        XCTAssertTrue(app.staticTexts["profile.name"].waitForExistence(timeout: 5))
        app.buttons["profile.logout"].tap()
        XCTAssertTrue(app.buttons["auth.submit"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 5: Run pass. Commit.**

---

# Phase 5 — Delivery tracking map

### Task 5.1: Courier model + CourierSimulator

**Files:**
- Create: `SushiGarden/SharedModels/Courier.swift`, `DeliveryAddress.swift`
- Create: `SushiGarden/Services/Delivery/CourierSimulator.swift`
- Test: `SushiGardenTests/Services/CourierSimulatorTests.swift`

- [ ] **Step 1: Failing tests**

```swift
// SushiGardenTests/Services/CourierSimulatorTests.swift
import XCTest
import CoreLocation
@testable import SushiGarden

@MainActor
final class CourierSimulatorTests: XCTestCase {
    private let start = CLLocationCoordinate2D(latitude: 51.66, longitude: 39.20)
    private let end   = CLLocationCoordinate2D(latitude: 51.67, longitude: 39.18)

    func test_progressInterpolatesPosition() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 0)
        XCTAssertEqual(sim.position.latitude, start.latitude, accuracy: 0.0001)
        sim.update(progress: 1)
        XCTAssertEqual(sim.position.latitude, end.latitude, accuracy: 0.0001)
        sim.update(progress: 0.5)
        XCTAssertEqual(sim.position.latitude, (start.latitude + end.latitude)/2, accuracy: 0.0001)
    }
    func test_etaCountsDown() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 0.25)
        XCTAssertEqual(sim.remainingSeconds, 75)
    }
    func test_progressClamped() {
        let sim = CourierSimulator(start: start, destination: end, etaSeconds: 100)
        sim.update(progress: 2.0)
        XCTAssertEqual(sim.position.latitude, end.latitude, accuracy: 0.0001)
        XCTAssertEqual(sim.remainingSeconds, 0)
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/SharedModels/Courier.swift
struct Courier: Equatable {
    let name: String
    let role: String
    static let demo = Courier(name: "Максим Винокур", role: "Курьер")
}
```
```swift
// SushiGarden/SharedModels/DeliveryAddress.swift
struct DeliveryAddress: Equatable {
    let title: String
    static let demo = DeliveryAddress(title: "Воронеж, Мира 36")
}
```
```swift
// SushiGarden/Services/Delivery/CourierSimulator.swift
import Foundation
import CoreLocation

@MainActor
final class CourierSimulator: ObservableObject {
    let start: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let etaSeconds: Int
    @Published private(set) var position: CLLocationCoordinate2D
    @Published private(set) var remainingSeconds: Int
    private var timer: Timer?

    init(start: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, etaSeconds: Int) {
        self.start = start; self.destination = destination; self.etaSeconds = etaSeconds
        self.position = start; self.remainingSeconds = etaSeconds
    }

    func update(progress raw: Double) {
        let p = min(max(raw, 0), 1)
        position = CLLocationCoordinate2D(
            latitude: start.latitude + (destination.latitude - start.latitude) * p,
            longitude: start.longitude + (destination.longitude - start.longitude) * p)
        remainingSeconds = Int(Double(etaSeconds) * (1 - p))
    }

    /// Drives `update(progress:)` over `etaSeconds` for the live screen. Not used in unit tests.
    func start(updateInterval: TimeInterval = 1) {
        let total = Double(etaSeconds)
        var elapsed = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] t in
            elapsed += updateInterval
            Task { @MainActor in
                self?.update(progress: elapsed / total)
                if elapsed >= total { t.invalidate() }
            }
        }
    }
    func stop() { timer?.invalidate(); timer = nil }
}
```

- [ ] **Step 4: Run pass. Step 5: Commit.**

---

### Task 5.2: TrackingViewModel + TrackingView (MapKit) (replaces TEMP-STUB)

**Files:**
- Create: `SushiGarden/Features/Tracking/ViewModel/TrackingViewModel.swift`
- Create: `SushiGarden/Features/Tracking/View/TrackingView.swift`
- Test: `SushiGardenTests/Features/TrackingViewModelTests.swift`, `SushiGardenUITests/TrackingUITests.swift`

- [ ] **Step 1: Failing unit test**

```swift
// SushiGardenTests/Features/TrackingViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class TrackingViewModelTests: XCTestCase {
    func test_exposesCourierAndAddress() {
        let vm = TrackingViewModel()
        XCTAssertEqual(vm.courier.name, "Максим Винокур")
        XCTAssertEqual(vm.address.title, "Воронеж, Мира 36")
        XCTAssertGreaterThan(vm.simulator.remainingSeconds, 0)
    }
    func test_etaTextFormat() {
        let vm = TrackingViewModel()
        vm.simulator.update(progress: 0) // full eta
        XCTAssertTrue(vm.etaText.contains("мин"))
    }
}
```

- [ ] **Step 2: Run, confirm fail. Step 3: Implement**

```swift
// SushiGarden/Features/Tracking/ViewModel/TrackingViewModel.swift
import Foundation
import CoreLocation

@MainActor
final class TrackingViewModel: ObservableObject {
    let courier = Courier.demo
    let address = DeliveryAddress.demo
    let restaurant = CLLocationCoordinate2D(latitude: 51.6608, longitude: 39.2003)
    let destination = CLLocationCoordinate2D(latitude: 51.6720, longitude: 39.1843)
    let simulator: CourierSimulator

    init() {
        simulator = CourierSimulator(
            start: CLLocationCoordinate2D(latitude: 51.6608, longitude: 39.2003),
            destination: CLLocationCoordinate2D(latitude: 51.6720, longitude: 39.1843),
            etaSeconds: 25 * 60)
    }
    func begin() { simulator.start() }
    func end() { simulator.stop() }
    var etaText: String { "\(max(1, simulator.remainingSeconds / 60)) мин" }
}
```

```swift
// SushiGarden/Features/Tracking/View/TrackingView.swift
import SwiftUI
import MapKit

struct TrackingView: View {
    let deps: Dependencies
    @StateObject private var vm = TrackingViewModel()
    @State private var camera: MapCameraPosition = .automatic
    init(deps: Dependencies) { self.deps = deps }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                Marker("Ресторан", coordinate: vm.restaurant).tint(.gray)
                Marker(vm.address.title, coordinate: vm.destination).tint(AppColor.accent)
                Annotation("Курьер", coordinate: vm.simulator.position) {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.title).foregroundStyle(AppColor.accent)
                }
                MapPolyline(coordinates: [vm.restaurant, vm.simulator.position])
                    .stroke(AppColor.accent, lineWidth: 3)
            }
            .accessibilityIdentifier(A11y.Tracking.map)
            .ignoresSafeArea(edges: .top)

            courierCard
        }
        .navigationTitle("Доставка")
        .onAppear {
            camera = .region(MKCoordinateRegion(
                center: vm.restaurant,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            vm.begin()
        }
        .onDisappear { vm.end() }
    }

    private var courierCard: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill").resizable().frame(width: 44, height: 44)
                .foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading) {
                Text(vm.courier.name).font(AppFont.productTitle).foregroundStyle(.white)
                Text(vm.courier.role).font(AppFont.weight).foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text(vm.etaText).font(AppFont.price).foregroundStyle(AppColor.accent)
        }
        .padding().background(AppColor.tabBar)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(Spacing.screenMargin)
        .accessibilityIdentifier(A11y.Tracking.courier)
    }
}
```
> Delete the `TrackingView` TEMP-STUB. Now run the full `CheckoutUITests.test_fullCheckoutFlow_reachesTracking` (Task 3.4).

- [ ] **Step 4: UI test**

```swift
// SushiGardenUITests/TrackingUITests.swift
import XCTest
final class TrackingUITests: XCTestCase {
    func test_trackingShowsCourierCard_afterCheckout() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        app.buttons["cart.checkout"].tap()
        app.textFields["checkout.name"].tap();  app.typeText("Саша")
        app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
        app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
        app.buttons["checkout.confirm"].tap()
        XCTAssertTrue(app.otherElements["tracking.courier"].waitForExistence(timeout: 8))
    }
}
```

- [ ] **Step 5: Run pass. Commit.**

---

# Phase 6 — Full UI-test sweep + polish

### Task 6.1: Orders-after-checkout UI test (cross-screen persistence)

**Files:**
- Test: `SushiGardenUITests/OrdersUITests.swift`

- [ ] **Step 1: Write test**

```swift
// SushiGardenUITests/OrdersUITests.swift
import XCTest
final class OrdersUITests: XCTestCase {
    func test_placedOrderAppearsInOrdersTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        app.buttons["cart.checkout"].tap()
        app.textFields["checkout.name"].tap();  app.typeText("Саша")
        app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
        app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
        app.buttons["checkout.confirm"].tap()
        _ = app.otherElements["tracking.courier"].waitForExistence(timeout: 8)
        app.buttons["tab.orders"].tap()
        XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
    }
}
```
> The UI-test `OrderStore` is in-memory per launch (`Dependencies` passes `inMemory: uiTest`), so the order persists within the session but not across relaunches — correct for deterministic tests.

- [ ] **Step 2: Run, confirm pass (all wiring exists). Step 3: Commit.**

---

### Task 6.2: Full-suite green + README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Run the entire suite**

```bash
xcodegen generate
xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' 2>&1 | tail -40
```
Expected: `** TEST SUCCEEDED **`, all unit + UI tests passing. Fix any failures before continuing.

- [ ] **Step 2: Write README** covering: what the app is, the Figma source, the architecture (SwiftUI/MVVM/async-await, AppDelegate shell, DI), how to run (`xcodegen generate` + open or `xcodebuild`), the two user-supplied files (`GoogleService-Info.plist`, `Mugesta.ttf`), the `-UITEST` / `-SEEDED_AUTH` launch arguments, and the test layout. (Do not add "Built with Claude Code" credit lines, per the user's standing preference — the commit trailer suffices.)

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "Add README and confirm full test suite green

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Self-review notes (coverage map)

- **SwiftUI + MVVM + async/await:** every Feature has View + `@MainActor` ViewModel; async used in `AuthViewModel.submit`, `CheckoutViewModel.confirm`, `AuthService`. ✓
- **Firebase registration:** Task 1.4 `FirebaseAuthService`, configured in Task 1.6; protocol + fake in 1.3. ✓
- **Figma images as placeholders:** Task 0.4 extraction script + `AppImage`; used in cards/detail/cart/promotions. ✓
- **MapKit map:** Phase 5 `TrackingView` with `Map`, markers, polyline, animated courier. ✓
- **UI tests for every screen:** Auth (1.8), Catalog (2.5), Cart (3.3), Checkout (3.4), Promotions (4.1), Profile (4.3), Tracking (5.2), Orders (6.1). ✓
- **Persistence (orders SwiftData, cart in-memory):** Task 3.1 `OrderStore`, `CartService` in-memory. ✓
- **Russian UI:** centralized `Strings`; views reference it. ✓
- **Fonts (Sen + Mugesta fallback):** Tasks 0.2/0.3, `AppFont.mugesta` fallback. ✓
- **TEMP-STUB bridges** (Dependencies services in 1.5; tab views in 1.8) are each explicitly deleted in their real task — searchable by `// TEMP-STUB` and `// TEMP-STUB:`. ✓
- **Type consistency:** `CartService` method names (`add`, `decrement`, `setQuantity`, `quantity(of:)`, `toggleAddOn`, `subtotal`, `addOnsTotal`, `clear`) used identically in `CatalogViewModel`, `ProductDetailViewModel`, `CartViewModel`, `CheckoutViewModel`. `OrderStore.save/allOrders` consistent across Orders/Profile/Checkout. ✓
