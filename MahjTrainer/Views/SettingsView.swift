import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                supportSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Restore", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }

    private var proSection: some View {
        Section("Membership") {
            if subscriptions.isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.felt)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock every room", systemImage: "lock.open.fill")
                }
            }
            Button("Restore Purchases") {
                Task {
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro ? "Pro restored!" : "No purchases found."
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button {
                requestReview()
            } label: {
                Label("Rate Mahj Trainer", systemImage: "star.fill")
            }
            Link(destination: URL(string: "mailto:jackwallner@gmail.com?subject=Mahj%20Trainer%20Feedback")!) {
                Label("Send Feedback", systemImage: "envelope.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            Text("Mahj Trainer teaches American Mah Jongg skills with original practice hands. It is not affiliated with or endorsed by the National Mah Jongg League. For official hands and values, pick up the current NMJL card.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Developer") {
            Toggle("Local Pro override", isOn: .init(
                get: { subscriptions.isPro },
                set: { subscriptions.setLocalOverride(isPro: $0) }
            ))
        }
    }
    #endif
}
