import SwiftUI
import SwiftData

@main
struct CeyizimApp: App {
    let container: ModelContainer

    init() {
        Typo.configureAppearance()
        let schema = Schema([CeyizCategory.self, CeyizItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Last resort so the app never crashes on launch. Data will not persist
            // in this mode, but this only happens if the store is corrupt.
            container = try! ModelContainer(for: schema,
                                             configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.rose)
                .font(Typo.body)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasOnboarded)
    }
}

enum AppTab: Hashable { case home, list, budget, settings }

struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("Özet", systemImage: "house.fill") }
                .tag(AppTab.home)
            ItemsListView()
                .tabItem { Label("Listem", systemImage: "checklist") }
                .tag(AppTab.list)
            BudgetView()
                .tabItem { Label("Harcamalar", systemImage: "turkishlirasign.circle.fill") }
                .tag(AppTab.budget)
            SettingsView()
                .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}
