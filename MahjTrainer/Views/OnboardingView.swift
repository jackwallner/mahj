import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var page = 0
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false

    private let lastPage = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                infoPage(
                    icon: "square.grid.3x3.fill",
                    title: "Learned mahj on Thursday?",
                    body: "Keep it. Lessons fade fast when the next game is a week away. Mahj Trainer gives you five-minute drills you can run anywhere, even standing in line.",
                    tiles: [.c(2), .dragon(.soap), .c(2), .b(6)]
                ).tag(0)
                infoPage(
                    icon: "rectangle.stack.fill",
                    title: "Drills, not games",
                    body: "Like practicing serves without playing a match. Swipe through flashcards, read racks, pick your Charleston pass, and get the why behind every answer.",
                    tiles: [.b(4), .b(5), .b(6), .joker]
                ).tag(1)
                infoPage(
                    icon: "figure.walk",
                    title: "Walk in confident",
                    body: "Know which dragon matches which suit, spot your section fast, and stop dreading the Charleston. Built for new players; no pressure, no timers, no opponents.",
                    tiles: [.dragon(.red), .dragon(.green), .flower]
                ).tag(2)
                trialPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
            footer
        }
        .background(Theme.background)
    }

    private func infoPage(icon: String, title: String, body bodyText: String, tiles: [Tile]) -> some View {
        VStack(spacing: 26) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 92, height: 92)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text(title)
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            TileRackView(tiles: tiles, tileWidth: 54)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var trialPage: some View {
        ScrollView {
            PaywallContent(selectedPlan: $selectedPlan)
                .padding(.horizontal, 24)
                .padding(.top, 24)
        }
    }

    /// Footer reserves identical space on every page so the CTA never shifts.
    private var footer: some View {
        VStack(spacing: 10) {
            pageDots
            Button {
                primaryAction()
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(page == lastPage ? selectedPlan.ctaTitle : "Continue")
                    }
                }
                .primaryCTA()
            }
            .disabled(purchasing)
            // Soft exit: same reserved height on all pages, only visible on the trial page.
            Button {
                finish()
            } label: {
                Text("Get Started")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(height: 30)
            .opacity(page == lastPage ? 1 : 0)
            .disabled(page != lastPage)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0...lastPage, id: \.self) { dot in
                Capsule()
                    .fill(dot == page ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == page ? 20 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: page)
            }
        }
        .padding(.bottom, 2)
    }

    private func primaryAction() {
        if page < lastPage {
            page += 1
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            if (try? await subscriptions.purchase(subscriptions.package(for: selectedPlan))) != nil {
                finish()
            }
        }
    }

    private func finish() {
        // RootView branches on this key, so setting it swaps Home in.
        progress.hasOnboarded = true
    }
}
