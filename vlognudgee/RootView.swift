//
//  RootView.swift
//  VlogNudge
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 0

    @AppStorage("hasCompletedOnboarding",
                store: UserDefaults(suiteName: AppConstants.appGroupID))
    private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingFlow()
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "calendar") }
                .tag(1)

            IdeasView()
                .tabItem { Label("Ideas", systemImage: "lightbulb.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .fullScreenCover(isPresented: captureBinding) {
            CaptureView(initialPrompt: appState.currentPrompt)
        }
        .onChange(of: appState.deepLink) { _, newValue in
            handleDeepLink(newValue)
        }
        .onOpenURL { url in
            handleURL(url)
        }
        .task {
            drainPendingIntentActions()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                drainPendingIntentActions()
            }
        }
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

    private var captureBinding: Binding<Bool> {
        Binding(
            get: {
                if case .capture = appState.deepLink { return true }
                return false
            },
            set: { presented in
                if !presented { appState.clearDeepLink() }
            }
        )
    }

    private func handleDeepLink(_ link: AppState.DeepLink) {
        switch link {
        case .ideaMemo:
            selectedTab = 2
        case .timeline:
            selectedTab = 1
        default:
            break
        }
    }

    private func handleURL(_ url: URL) {
        // vlognudge://record, vlognudge://idea, vlognudge://timeline
        switch url.host {
        case "record":
            appState.requestCapture(prompt: nil)
        case "idea":
            appState.deepLink = .ideaMemo
        case "timeline":
            selectedTab = 1
        default:
            break
        }
    }
}
