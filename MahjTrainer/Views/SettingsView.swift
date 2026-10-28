import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showPaywall = false
    @State private var showWhatsNew = false
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?
    @State private var restoring = false
    @State private var showFeedback = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                practiceSection
                proSection
                dataSection
                supportSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.jade)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.ink)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView(source: "mahj_settings_sheet") }
            .sheet(isPresented: $showWhatsNew) {
                if let release = WhatsNew.currentRelease {
                    WhatsNewSheet(release: release) {
                        showWhatsNew = false
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            showPaywall = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showFeedback) {
                ReviewPromptSheet(initialStep: .feedback)
            }
            .alert("Restore", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .alert("Notifications are off", isPresented: $settings.reminderPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Mahj Trainer cannot send reminders until notifications are turned on in iOS Settings.")
            }
            .alert("Reset all progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    progress.resetAll()
                    PracticeRecordStore.shared.resetAll()
                    MahjMinuteStore.shared.resetAll()
                    MonthlyChallengeStore.shared.resetAll()
                    OrdinaryRunStore.shared.clear(OrdinaryRunStore.shared.inProgress?.id ?? "")
                    HandPlayStore.shared.resetAll()
                    MasteryLedger.shared.resetAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your streak, completed drills, and practice history will be cleared. Purchases are not affected.")
            }
        }
    }

    /// The system header grey measured under 4.5:1 on the cream.
    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title).foregroundStyle(Theme.inkSecondary)
    }

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
        } header: {
            sectionHeader("Appearance")
        }
    }

    private var practiceSection: some View {
        Section {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle("Sound Effects", isOn: $settings.soundEnabled)
            Toggle("Daily Reminder", isOn: $settings.reminderEnabled)
            if settings.reminderEnabled {
                DatePicker("Reminder Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
            }
            if subscriptions.isPro {
                NavigationLink {
                    GameNightPrepView()
                } label: {
                    Label("Game Night Prep", systemImage: "person.2.fill")
                }
            }
        } header: {
            sectionHeader("Practice")
        }
    }

    /// Reset gets its own section. A destructive red button sitting between
    /// Haptics and Sound Effects is a trap for anyone who taps to see what
    /// something does.
    private var dataSection: some View {
        Section {
            NavigationLink {
                StatsView()
            } label: {
                Label("Your Progress", systemImage: "chart.bar.fill")
            }
            Button("Reset Progress", role: .destructive) {
                showResetConfirm = true
            }
            // The system red measured 3.6:1 on the row; the tile red is the
            // same warning at 6:1.
            .foregroundStyle(Theme.crakRed)
        } header: {
            sectionHeader("Your Practice History")
        }
    }

    private var proSection: some View {
        Section {
            if subscriptions.isPro {
                Label("\(Membership.name) unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.jade)
                // Lifetime has no expiration and nothing to manage.
                if subscriptions.expirationDate != nil {
                    Link("Manage Subscription", destination: PaywallLinks.manageSubscriptions)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Get \(Membership.name)", systemImage: "sparkles")
                }
            }
            Button {
                guard !restoring else { return }
                restoring = true
                Task {
                    defer { restoring = false }
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro
                            ? String(localized: "\(Membership.name) restored!")
                            : String(localized: "No previous purchase found on this Apple Account.")
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    Text("Restore Purchases")
                    if restoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(restoring)
        } header: {
            sectionHeader("Membership")
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink {
                ReferenceView()
            } label: {
                Label("Reference & Glossary", systemImage: "book.closed.fill")
            }
            NavigationLink {
                HowToPlayView()
            } label: {
                Label("How to Play", systemImage: "book.fill")
            }
            if WhatsNew.currentRelease != nil {
                Button {
                    showWhatsNew = true
                } label: {
                    Label("What's New", systemImage: "sparkle")
                }
            }
            Button {
                // A button never calls `requestReview()`: Apple may show
                // nothing and the tap would look broken. It opens the
                // write-review page, which always works.
                ReviewPromptTracker.markOpenedWriteReview()
                openURL(AppStoreLinks.writeReviewURL)
            } label: {
                Label("Rate Mahj Trainer", systemImage: "star.fill")
            }
            Button {
                showFeedback = true
            } label: {
                Label("Send Feedback", systemImage: "bubble.left.fill")
            }
        } header: {
            sectionHeader("Support")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            // Members never see the paywall's links again, so the policy
            // lives here for everyone.
            Link("Privacy Policy", destination: PaywallLinks.privacy)
            Text("Mahj Trainer teaches American Mah Jongg skills with original practice hands. It is not affiliated with or endorsed by the National Mah Jongg League. For official hands and values, pick up the current NMJL card.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            sectionHeader("About")
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section {
            Toggle("Local Pro override", isOn: .init(
                get: { subscriptions.isPro },
                set: { subscriptions.setLocalOverride(isPro: $0) }
            ))
        } header: {
            sectionHeader("Developer")
        }
    }
    #endif
}
