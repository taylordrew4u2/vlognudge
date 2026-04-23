//
//  RootView.swift
//  VlogNudge
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 0
    @State private var showCapture = false

    @AppStorage("hasCompletedOnboarding",
                store: UserDefaults(suiteName: AppConstants.appGroupID))
    private var hasCompletedOnboarding: Bool = false

    init() {
        // Theme the UIKit-backed tab bar to match 6:3:1 palette
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(VNColor.secondary)
        tabAppearance.shadowColor = .clear

        // Normal state
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.38)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.38)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs

        // Selected state — accent color
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(VNColor.accent)
        ]
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(VNColor.accent)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Theme navigation bars globally
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(VNColor.dominant)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(VNColor.accent)
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingFlow()
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCapture) {
            CaptureView(initialPrompt: appState.currentPrompt)
        }
        .onChange(of: appState.deepLink, initial: true) { _, newValue in
            switch newValue {
            case .capture:
                showCapture = true
            case .ideaMemo:
                selectedTab = 3
                appState.clearDeepLink()
            case .timeline:
                selectedTab = 2
                appState.clearDeepLink()
            case .none:
                break
            }
        }
        .onChange(of: showCapture) { _, presented in
            if !presented {
                appState.clearDeepLink()
            }
        }
        .task {
            drainPendingIntentActions()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                drainPendingIntentActions()
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    drainPendingIntentActions()
                }
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(1)

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "calendar") }
                .tag(2)

            IdeasView()
                .tabItem { Label("Ideas", systemImage: "lightbulb.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(VNColor.accent)
    }

    private func drainPendingIntentActions() {
        let actions = AppIntentsInbox.drain()
        guard !actions.isEmpty else { return }
        for action in actions {
            switch action {
            case .record:
                appState.requestCapture(prompt: nil)
            case .idea:
                appState.deepLink = .ideaMemo
            case .notNow:
                Task { await NudgeScheduler.shared.registerNotNow() }
            case .skipHour:
                Task { await NudgeScheduler.shared.skipNextHour() }
            }
        }
    }
}
