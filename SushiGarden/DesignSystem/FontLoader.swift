// SushiGarden/DesignSystem/FontLoader.swift
import CoreText
import Foundation

enum FontLoader {
    /// Idempotent. Registers bundled fonts; safe if already registered or missing.
    /// The Fonts folder is bundled as a folder-reference resource, so TTFs live at
    /// Bundle.main/<bundle>/Fonts/<name>.ttf — we locate them via the folder URL.
    static func registerAll() {
        guard let fontsFolder = Bundle.main.url(forResource: "Fonts", withExtension: nil) else { return }
        for name in ["Sen-Regular", "Sen-Bold"] {
            let url = fontsFolder.appendingPathComponent("\(name).ttf")
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
