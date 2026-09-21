import Observation
import SwiftUI
import UIKit

/// The user-chosen accent colour, and the six shades the app derives from it.
///
/// A free colour picker has one real failure mode: white text on the accent.
/// A pale yellow would give roughly 1.5:1 against white and make every primary
/// button unreadable, so the hue belongs to the user while the *tone* stays the
/// app's. `AccentTheme` keeps the hue and saturation as picked, then solves for
/// the brightness that lands the accent on a target relative luminance — the
/// same one the original rose sits on. Every hue therefore ships the same
/// contrast the brand shipped, and the picker shows the resolved colour back so
/// what you choose is what you see.
struct AccentTheme: Equatable {

    let hue: Double            // 0…1
    let saturation: Double     // 0…1, clamped to a usable band
    let luminance: Double      // target WCAG relative luminance for the accent

    /// Brightness that lands the accent on `luminance`. Solved once here rather
    /// than on every colour read — `Palette.rose` is touched dozens of times a
    /// frame.
    private let brightness: Double

    /// The original brand rose (#D4667F). Reproduced exactly by the derivation
    /// below, so the default theme is pixel-identical to the pre-theme app.
    static let brand = AccentTheme(hue: 346.0 / 360.0, saturation: 0.519, luminance: 0.250)

    // Bands. Saturation keeps a grey pick from killing the UI and a neon pick
    // from screaming; luminance keeps white-on-accent between 3.4:1 and 4.8:1
    // (the untouched rose was 3.5:1).
    static let saturationRange = 0.30...0.82
    static let luminanceRange = 0.17...0.26

    init(hue: Double, saturation: Double, luminance: Double) {
        let h = hue.truncatingRemainder(dividingBy: 1).magnitude
        let s = saturation.clamped(to: Self.saturationRange)
        let l = luminance.clamped(to: Self.luminanceRange)
        self.hue = h
        self.saturation = s
        self.luminance = l
        self.brightness = Self.solveBrightness(hue: h, saturation: s, luminance: l)
    }

    /// Reads a colour the user picked in the wheel and normalises it.
    init(picked color: Color) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            self = .brand
            return
        }
        // A near-grey pick has no usable hue, so keep the brand's saturation
        // rather than washing the whole app out.
        let rgb = RGB(h: Double(h), s: Double(s), b: Double(b))
        self.init(hue: Double(h),
                  saturation: s < 0.06 ? AccentTheme.brand.saturation : Double(s),
                  luminance: rgb.relativeLuminance)
    }

    // MARK: - Derived shades
    //
    // The offsets are the measured relationships between the original palette
    // entries, so any hue keeps the proportions the rose had.

    /// Primary accent — buttons, the progress ring, selected chips.
    var accentLight: Color { RGB(h: hue, s: saturation, b: brightness).color }
    /// One step down, for pressed states and the deeper half of gradients.
    var deepLight: Color { RGB(h: hue, s: min(1, saturation + 0.06), b: brightness - 0.11).color }
    /// The tinted card background.
    var softLight: Color { RGB(h: hue, s: saturation * 0.18, b: 0.98).color }

    var accentDark: Color { RGB(h: hue, s: saturation * 0.76, b: min(0.94, brightness + 0.068)).color }
    var deepDark: Color { RGB(h: hue, s: saturation * 0.875, b: min(0.92, brightness - 0.012)).color }
    var softDark: Color { RGB(h: hue, s: min(0.45, saturation * 0.80), b: 0.275).color }

    /// The barely-there tint on secondary cards — a green theme should not
    /// leave pink cards behind.
    var cardTintLight: Color { RGB(h: hue, s: saturation * 0.092, b: 0.984).color }
    var cardTintDark: Color { RGB(h: hue, s: min(0.34, saturation * 0.56), b: 0.188).color }

    /// Luminance rises monotonically with brightness at a fixed hue and
    /// saturation, so a short bisection lands on the target exactly enough.
    private static func solveBrightness(hue: Double, saturation: Double, luminance: Double) -> Double {
        var low = 0.05, high = 1.0
        for _ in 0..<18 {
            let mid = (low + high) / 2
            if RGB(h: hue, s: saturation, b: mid).relativeLuminance < luminance {
                low = mid
            } else {
                high = mid
            }
        }
        return (low + high) / 2
    }

    // MARK: - Persistence

    static func load(from defaults: UserDefaults = .standard) -> AccentTheme {
        guard defaults.object(forKey: SettingsKeys.accentHue) != nil else { return .brand }
        return AccentTheme(hue: defaults.double(forKey: SettingsKeys.accentHue),
                           saturation: defaults.double(forKey: SettingsKeys.accentSaturation),
                           luminance: defaults.double(forKey: SettingsKeys.accentLuminance))
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(hue, forKey: SettingsKeys.accentHue)
        defaults.set(saturation, forKey: SettingsKeys.accentSaturation)
        defaults.set(luminance, forKey: SettingsKeys.accentLuminance)
    }

    /// Hues offered as one-tap starting points. The picker still accepts anything.
    static let presets: [(name: String, theme: AccentTheme)] = [
        ("Gül", .brand),
        ("Bordo", AccentTheme(hue: 352 / 360, saturation: 0.66, luminance: 0.185)),
        ("Mercan", AccentTheme(hue: 12 / 360, saturation: 0.62, luminance: 0.250)),
        ("Altın", AccentTheme(hue: 38 / 360, saturation: 0.70, luminance: 0.260)),
        ("Adaçayı", AccentTheme(hue: 145 / 360, saturation: 0.40, luminance: 0.240)),
        ("Deniz", AccentTheme(hue: 192 / 360, saturation: 0.62, luminance: 0.230)),
        ("Gök", AccentTheme(hue: 214 / 360, saturation: 0.52, luminance: 0.220)),
        ("Lavanta", AccentTheme(hue: 262 / 360, saturation: 0.44, luminance: 0.210)),
        ("Erik", AccentTheme(hue: 318 / 360, saturation: 0.48, luminance: 0.205)),
    ]
}

/// The app's current accent. Views read it through `Palette`, and because this
/// is `@Observable` every view that draws an accent colour redraws by itself
/// when the theme changes — no restart, no manual refresh.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private(set) var accent: AccentTheme

    private init() {
        accent = AccentTheme.load()
    }

    func apply(_ theme: AccentTheme) {
        guard theme != accent else { return }
        accent = theme
        theme.save()
    }
}

// MARK: - Colour maths

extension AccentTheme {

    /// A plain sRGB triple, so hue rotation and luminance stay in one place.
    struct RGB {
        var r: Double, g: Double, b: Double

        init(r: Double, g: Double, b: Double) {
            self.r = r.clamped(to: 0...1)
            self.g = g.clamped(to: 0...1)
            self.b = b.clamped(to: 0...1)
        }

        /// HSB → sRGB.
        init(h: Double, s: Double, b brightness: Double) {
            let h = h.truncatingRemainder(dividingBy: 1).magnitude * 6
            let s = s.clamped(to: 0...1)
            let v = brightness.clamped(to: 0...1)
            let i = floor(h)
            let f = h - i
            let p = v * (1 - s)
            let q = v * (1 - s * f)
            let t = v * (1 - s * (1 - f))
            switch Int(i) % 6 {
            case 0: self.init(r: v, g: t, b: p)
            case 1: self.init(r: q, g: v, b: p)
            case 2: self.init(r: p, g: v, b: t)
            case 3: self.init(r: p, g: q, b: v)
            case 4: self.init(r: t, g: p, b: v)
            default: self.init(r: v, g: p, b: q)
            }
        }

        /// WCAG relative luminance, used to keep white text legible on the accent.
        var relativeLuminance: Double {
            func channel(_ c: Double) -> Double {
                c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }

        var color: Color { Color(red: r, green: g, blue: b) }
    }
}

fileprivate extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
