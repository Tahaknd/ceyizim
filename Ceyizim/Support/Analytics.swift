import Foundation
import UIKit

/// Minimal PostHog event capture over their public HTTP API — no SDK dependency.
/// Uses a random, app-generated id (not IDFA/IDFV), never linked to name, email,
/// or any other identity in the app. Fire-and-forget: never blocks the UI and
/// silently drops events when offline.
enum Analytics {
    private static let apiKey = "phc_v5LAhymhZEt4jgSqt6YFz2Xc3SsrS3J3zhkah35AjsY9"
    private static let endpoint = URL(string: "https://eu.i.posthog.com/capture/")!

    private static let distinctID: String = {
        let key = "posthogDistinctID"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }()

    static func track(_ event: String, _ properties: [String: Any] = [:]) {
        var props = properties
        props["distinct_id"] = distinctID
        let payload: [String: Any] = [
            "api_key": apiKey,
            "event": event,
            "properties": props,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        URLSession.shared.dataTask(with: request).resume()
    }

    /// Screen-view convenience — call from `.onAppear` on each top-level screen.
    static func screen(_ name: String) {
        track("screen_viewed", ["screen": name])
    }

    /// Launch event, tagged with `$set` person properties so retention/engagement
    /// can be segmented by version and by cohort (template used, wedding date set)
    /// in PostHog without a separate identify call.
    static func trackAppOpened() {
        let defaults = UserDefaults.standard
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        track("app_opened", [
            "$set": [
                "app_version": appVersion,
                "ios_version": UIDevice.current.systemVersion,
                "has_wedding_date": defaults.double(forKey: SettingsKeys.weddingDate) > 0,
                "used_template": defaults.bool(forKey: SettingsKeys.seededTemplate),
            ],
        ])
    }

    // MARK: - Sessions

    /// In-memory only: a cold launch or a background→foreground return both start
    /// a session; `.inactive` (app switcher, notification banner) is ignored so it
    /// doesn't fragment one real session into several.
    private static var sessionStartedAt: Date?

    static func sessionStarted() {
        guard sessionStartedAt == nil else { return }
        sessionStartedAt = Date()
        track("session_started")
    }

    static func sessionEnded() {
        guard let start = sessionStartedAt else { return }
        sessionStartedAt = nil
        track("session_ended", ["duration_seconds": Int(Date().timeIntervalSince(start))])
    }
}
