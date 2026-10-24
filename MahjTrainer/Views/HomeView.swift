import SwiftUI

/// Home is the lobby: Get Started, then the rooms as doors. The drills
/// themselves live one level down in `RoomView`. (Home used to list every
/// drill flat; once each room grew a Mahj+ extra set that list ran to a dozen
/// rows and the rooms stopped reading as places.)
///
/// The rooms are what Home is FOR, so everything else earns its space or
/// leaves: the stats ride beside the title instead of eating a row of their
/// own, and the primer card disappears the moment it has been read.
struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: AppRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var membershipWaitOver = false
    @StateObject private var ordinaryRuns = OrdinaryRunStore.shared
    @StateObject private var records = PracticeRecordStore.shared
    @StateObject private var monthlyStore = MonthlyChallengeStore.shared
    @StateObject private var handPlay = HandPlayStore.shared
    @StateObject private var ledger = MasteryLedger.shared
    @State private var path: [AppDestination] = []
    @State private var showPaywall = false
    #if DEBUG
    /// `-mahj.previewTrialOffer` opens the result-screen trial sheet over
    /// Home, for screenshots and layout checks.
    @State private var previewTrialOffer = ProcessInfo.processInfo.arguments.contains("-mahj.previewTrialOffer")
    #endif
    @State private var showSettings = false
    @State private var showWhatsNew = false
    /// Non-nil while the one churn question is up.
    @State private var churnPrompt: ChurnMoment?
    /// False while a room, drill or deep-linked screen is pushed over Home.
    /// Room links are view-based, so `path` alone cannot tell.
    @State private var homeOnScreen = false
    /// "When's your game night?" is shown to members until they set one or
    /// wave it off. The reminder is the hook that matches how people play,
    /// and it was buried two taps deep in a tile nobody opened in week one.
    @AppStorage("mahj.gameNightCardDismissed") private var gameNightCardDismissed = false
    @State private var upgrade = UnlockContinuation<AppDestination>()
    @State private var highlightedRoomID: String?
    @AppStorage("mahj.skillLevel") private var skillLevel = ""
    /// Set once the primer has been read all the way through. After that it
    /// lives in Settings only; a permanent "How to Play" card on Home is a
    /// standing tax on the rooms below it.
    @AppStorage("mahj.hasReadPrimer") private var hasReadPrimer = false
    /// One-shot hint set by `HowToPlayView`'s end-of-primer recommendation:
    /// the room id to highlight/scroll to the next time Home appears.
    @AppStorage("mahj.recommendedRoomHint") private var recommendedRoomHint = ""

    private var showsPrimerCard: Bool { skillLevel == "new" && !hasReadPrimer }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    homeContent
                    .padding(.bottom, 24)
                }
                .onAppear {
                    homeOnScreen = true
                    consumeRecommendedRoomHint(proxy: proxy)
                    consumePendingDestination()
                    recordMastery()
                    homeIsBareAgain()
                }
                .onDisappear { homeOnScreen = false }
                .onChange(of: showSettings) { _, isShowing in
                    if !isShowing { consumeRecommendedRoomHint(proxy: proxy) }
                }
            }
            .background(Theme.background)
            .toolbar {
                // The reference is a toolbar button rather than a card
                // because the moment it is wanted is mid-game, and it must
                // cost Home no vertical space to be worth that.
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ReferenceView()
                    } label: {
                        Image(systemName: "book")
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .accessibilityLabel("Reference and glossary")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            // No `.toolbarBackground(.hidden)`: it also removed the system's
            // scroll-edge blur, and scrolled rooms ran straight under the
            // clock and the book and gear buttons. The bar is still clear at
            // the top of Home.
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .quickSession:
                    OrdinaryRunEntryView(id: SessionBuilder.sessionDrill.id, title: SessionBuilder.sessionDrill.title) {
                        QuickSessionView(items: SessionBuilder.quickSession(
                            seen: progress.seenItems, missed: progress.missedItems, includePro: subscriptions.isPro))
                    }
                case .ordinaryRun:
                    SavedOrdinaryRunView()
                case .gameNightPrepSession:
                    QuickSessionView(gameNightPrep: gameNightPrepItems)
                case .monthlyChallenge:
                    MonthlyChallengeView()
                case .endlessPicker: EndlessPickerView()
                case .gameNightPrep: GameNightPrepView()
                case .timedChallenge: PracticeRunView(mode: .timed)
                case .handPlay: HandPlayView()
                case .review:
                    PracticeRunView(mode: .review, items: SessionBuilder.reviewSession(
                        ids: records.reviewQueue(among: SessionBuilder.reviewableIDs(includePro: true)), includePro: true))
                }
            }
            .sheet(isPresented: $showPaywall, onDismiss: {
                if let destination = upgrade.finish(isMember: subscriptions.isPro) { path.append(destination) }
                homeIsBareAgain()
            }) { PaywallView(source: "mahj_home_sheet") }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showWhatsNew) {
                if let release = WhatsNew.currentRelease {
                    WhatsNewSheet(release: release) {
                        showWhatsNew = false
                        // The sheet cannot present the paywall while it is
                        // dismissing, so hand off on the next runloop.
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            showPaywall = true
                        }
                    }
                }
            }
            .onChange(of: showWhatsNew) { _, isShowing in
                if !isShowing { homeIsBareAgain() }
            }
            .onChange(of: showSettings) { _, isShowing in
                if !isShowing { homeIsBareAgain() }
            }
            .onChange(of: subscriptions.offerings != nil) { _, loaded in
                // The tracking and challenge switches ride on the offering:
                // act on them once it is known.
                guard loaded else { return }
                MonthlyChallengeReminder.refresh()
                Task { await askForTrackingIfNeeded() }
            }
            .onChange(of: churnPrompt) { _, moment in
                if moment == nil { Task { await askForTrackingIfNeeded() } }
            }
            .sheet(item: $churnPrompt) { moment in
                ReviewPromptSheet(initialStep: .churn(moment))
            }
            .onChange(of: subscriptions.pendingChurnMoment) { _, _ in presentChurnPromptIfNeeded() }
            .onChange(of: records.records.count) { _, _ in recordMastery() }
            .onChange(of: router.pendingDestination) { _, _ in consumePendingDestination() }
            .onChange(of: subscriptions.membershipResolved) { _, _ in recordMastery() }
            .onChange(of: subscriptions.isPro) { _, _ in recordMastery() }
            .onChange(of: subscriptions.membershipResolved) { _, _ in consumePendingDestination() }
            .onChange(of: subscriptions.isPro) { _, isMember in
                if isMember {
                    if showPaywall {
                        showPaywall = false
                    } else {
                        consumePendingDestination()
                    }
                } else if settings.gameNightReminderEnabled {
                    settings.gameNightReminderEnabled = false
                }
            }
            .onChange(of: showPaywall) { _, isShowing in
                if !isShowing { homeIsBareAgain() }
            }
            #if DEBUG
            .sheet(isPresented: $previewTrialOffer) { TrialOfferSheet(context: .drillResult, auto: false) }
            #endif
        }
        .tint(Theme.jade)
    }

    @ViewBuilder
    private var homeContent: some View {
        // Two columns only while the type fits them. At accessibility sizes
        // an iPad's half-width columns broke room names into fragments
        // ("Th / e / Ma / ste / r"), so it gets the phone's single column.
        if horizontalSizeClass == .regular, !dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 18) {
                header
                HStack(alignment: .top, spacing: 20) {
                    todayColumn
                    roomsColumn
                }
                disclaimerFooter
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: Theme.wideContentWidth)
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 14) {
                header
                todaySession
                if showsPrimerCard { howToPlayCard }
                if let round = challengeCardRound { monthlyChallengeCard(round) }
                if showsGameNightCard { gameNightCard }
                trainingSection
                roomsColumn
                if !subscriptions.isPro { upgradeCard }
                disclaimerFooter
            }
            .padding(.horizontal)
            .frame(maxWidth: Theme.wideContentWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var todayColumn: some View {
        VStack(spacing: 14) {
            todaySession
            if showsPrimerCard { howToPlayCard }
            if let round = challengeCardRound { monthlyChallengeCard(round) }
            if showsGameNightCard { gameNightCard }
            trainingSection
            if !subscriptions.isPro { upgradeCard }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var showsGameNightCard: Bool {
        subscriptions.isPro && progress.hasPracticedSinceOnboarding
            && !settings.gameNightReminderEnabled && !gameNightCardDismissed
    }

    /// Today's mastery, written to the ledger so the week-over-week gain has
    /// something to measure from. Cheap, and idempotent within a day.
    private func recordMastery() {
        // Before RevenueCat answers, a member reads as free and the day's
        // entry would drop every Mahj+ item, faking a gain the next day.
        guard subscriptions.membershipResolved else { return }
        ledger.record(records.masteryByRoom(isMember: subscriptions.isPro))
    }

    /// The one question asked when a membership turns toward the exit. Waits
    /// for a drawn, bare Home (no drill pushed, no sheet up) and is only spent
    /// once it is actually shown; a covered Home retries when it is bare again.
    private func presentChurnPromptIfNeeded() {
        guard subscriptions.pendingChurnMoment != nil, progress.hasOnboarded else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let moment = subscriptions.pendingChurnMoment, homeIsBare else { return }
            subscriptions.consumeChurnMoment()
            churnPrompt = moment
        }
    }

    /// Nothing pushed and no sheet up: the only state Home may put a prompt on.
    private var homeIsBare: Bool {
        homeOnScreen && path.isEmpty && !showWhatsNew && !showPaywall && !showSettings && churnPrompt == nil
    }

    /// A sheet closed or the player came back to Home: anything that waited
    /// for a bare Home gets its turn (the churn question first, then ATT).
    private func homeIsBareAgain() {
        presentWhatsNewIfNeeded()
        presentChurnPromptIfNeeded()
        Task { await askForTrackingIfNeeded() }
    }

    private var roomsColumn: some View {
        VStack(spacing: 14) {
            roomsHeading
            ForEach(DrillLibrary.rooms) { room in
                roomCard(room)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var todaySession: some View {
        if let run = ordinaryRuns.inProgress {
            Button {
                path.append(.ordinaryRun)
            } label: {
                Label("Resume \(run.drill.title)", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.jade)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .themedCard(corner: 16)
            }
            .buttonStyle(PressableCardStyle())
        }
        if progress.quickSessionCompletedToday() {
            getStartedDoneCard
        } else {
            getStartedCard
        }
    }

    private var gameNightPrepItems: [QuickItem] {
        SessionBuilder.gameNightPrep(
            seen: progress.seenItems,
            missed: progress.missedItems,
            dueIDs: records.reviewQueue(among: SessionBuilder.reviewableIDs(includePro: true)),
            weakestRoomID: records.weakestRoom()?.id
        )
    }

    private func consumePendingDestination() {
        // A member opening a notification cold has isPro false until the
        // customer record loads; wait for it rather than sell them a paywall.
        if !subscriptions.membershipResolved, !membershipWaitOver,
           let waiting = router.pendingDestination, !waiting.isFree {
            // Offline with no cached record it may never resolve: give it a
            // few seconds, then fall back to the normal paywall guard.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                membershipWaitOver = true
                consumePendingDestination()
            }
            return
        }
        guard let destination = router.consumePendingDestination() else { return }
        // Switched off remotely: the event link and an old reminder just open Home.
        if destination == .monthlyChallenge, !showsMonthlyChallenge { return }
        guard destination.isFree || subscriptions.isPro else {
            upgrade.destination = destination
            showPaywall = true
            return
        }
        path = [destination]
    }

    /// The post-update note, once. Deliberately deferred a beat so it lands on
    /// a drawn Home rather than racing the first frame, and never over a
    /// screen the player opened from a notification or the challenge link;
    /// it waits for them to come back to Home.
    private func presentWhatsNewIfNeeded() {
        guard WhatsNew.shouldPresent(hasOnboarded: progress.hasOnboarded) else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard homeIsBare, WhatsNew.shouldPresent(hasOnboarded: progress.hasOnboarded) else { return }
            // Seen once shown: a swipe-down dismiss must not bring it back
            // every time Home is bare again.
            WhatsNew.markSeen()
            WhatsNew.shownThisLaunch = true
            showWhatsNew = true
        }
    }

    /// Apple's tracking prompt (Meta ads), only after a trial start or a
    /// purchase (Jack 2026-10-19), on the next bare Home: never at launch,
    /// never in onboarding, never over a sheet or a pushed screen. Only
    /// paying players are asked, and soon enough for `meta-trial-relay` to
    /// count a consented trial. Anything covering Home just defers it until
    /// Home is bare again, and a launch that showed What's New defers it to
    /// the next launch.
    ///
    /// The `att_prompt` switch lives in the offering, which a cold launch may
    /// not have yet; with no offering there is no ask, and the offering
    /// arriving tries again.
    private func askForTrackingIfNeeded() async {
        guard MetaAds.shouldAskForTracking, MetaAds.askAfterPurchase, progress.hasOnboarded,
              !WhatsNew.shownThisLaunch else { return }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        guard subscriptions.remoteConfigKnown, subscriptions.isOn(.attPrompt), homeIsBare else { return }
        await MetaAds.requestTracking()
    }

    /// Consumes the one-shot recommendation hint: scrolls to and briefly
    /// highlights the recommended room's card, then clears the hint so it
    /// only ever fires once per recommendation.
    private func consumeRecommendedRoomHint(proxy: ScrollViewProxy) {
        guard !recommendedRoomHint.isEmpty else { return }
        let roomID = recommendedRoomHint
        recommendedRoomHint = ""
        guard DrillLibrary.rooms.contains(where: { $0.id == roomID }) else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                proxy.scrollTo(roomID, anchor: .center)
                highlightedRoomID = roomID
            }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(.easeOut(duration: 0.4)) { highlightedRoomID = nil }
        }
    }

    // MARK: - Header (title left, stats right, one row total)

    /// Title and stats. On a regular width they share one row; on a phone they
    /// cannot.
    ///
    /// The toolbar draws no background, so Home's content sits directly under
    /// the Settings gear. At 402 points the trailing stats chip ran to x 386
    /// while the gear occupied x 348 to x 379 at an overlapping height, so the
    /// two controls were literally on top of each other and the gear looked
    /// like part of the progress chip. Stacking the chips under the title on
    /// compact widths costs one row and removes the collision outright, rather
    /// than tuning a padding that only holds at one text size.
    @ViewBuilder
    private var header: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top) {
                headerTitle
                Spacer(minLength: 8)
                statsRow
                    .padding(.top, 4)
            }
            .padding(.top, 2)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                headerTitle
                statsRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mahj Trainer")
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
            Text("Your seat at the table.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    /// The chips were already the honest summary of practice, so they are also
    /// the door to the full breakdown rather than yet another row competing
    /// with the rooms.
    private var statsLink: some View {
        NavigationLink {
            StatsView()
        } label: {
            // Three chips at the largest text sizes overrun a small phone.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { statChips }
                VStack(alignment: .leading, spacing: 8) { statChips }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens your progress breakdown")
    }

    @ViewBuilder private var statChips: some View {
        statChip(value: progress.currentStreak(), icon: "flame.fill", color: Theme.coral,
                 label: "\(progress.currentStreak()) day streak")
        statChip(value: progress.totalSessions, icon: "checkmark.seal.fill", color: Theme.jade,
                 label: "\(progress.totalSessions) drills done")
        // Only ever positive. A week that went backwards is not news
        // worth a chip; the ring already says where things stand.
        if let gain = ledger.weeklyGain() {
            statChip(value: gain, icon: "arrow.up.right", color: Theme.plum,
                     label: "\(gain) \(gain == 1 ? "question" : "questions") locked in this week", prefix: "+")
        }
    }

    /// The stats, then the challenge chip once today's round is played. The
    /// chip drops to its own line when large text leaves no room beside them.
    private var statsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                statsLink
                challengeChip
            }
            VStack(alignment: .leading, spacing: 8) {
                statsLink
                challengeChip
            }
        }
    }

    private func statChip(value: Int, icon: String, color: Color, label: String, prefix: String = "") -> some View {
        chipBody(text: "\(prefix)\(value)", icon: icon, color: color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }

    private func chipBody(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }

    /// The one-tap way in: builds a short mixed session, no browsing needed.
    private var getStartedCard: some View {
        Button {
            path.append(.quickSession)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    // `onFill`, not white: dark mode lightens the jade, and
                    // white on it measured 2.45:1.
                    Text("Get Started")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.onFill)
                    Text("A five-minute mix of what you need next")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onFill.opacity(0.9))
                }
                Spacer(minLength: 4)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.onFill)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Theme.jade, Theme.jade.opacity(0.82)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
            )
            .shadow(color: Theme.jade.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Today's Get Started is spent. Rather than hand back the same questions
    /// (a repeat teaches nothing), the card rests and points at the rooms for
    /// more practice, and comes back fresh tomorrow.
    private var getStartedDoneCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.jade)
                .frame(width: 44, height: 44)
                .background(Theme.jade.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Today's session is done")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("A fresh mix lands tomorrow. Keep going in any room below.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    /// Shown only until the primer has actually been read; after that it's a
    /// Settings row like every other reference material.
    private var howToPlayCard: some View {
        NavigationLink {
            HowToPlayView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("How to Play")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("New here? Start with the five-minute primer")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(12)
            .themedCard(corner: 16)
        }
        .buttonStyle(PressableCardStyle())
    }

    /// `monthly_challenge: off` in the offering metadata pulls the challenge
    /// without a release.
    private var showsMonthlyChallenge: Bool { subscriptions.isOn(.monthlyChallenge) }

    /// Today's challenge round, for players who have finished a practice of
    /// their own after the tour: a brand-new player's Home stays the 1.3.2
    /// lobby, with Get Started the obvious first tap. The event link opens
    /// the challenge for anyone.
    private var homeChallengeRound: ChallengeRound? {
        guard showsMonthlyChallenge, progress.hasPracticedSinceOnboarding else { return nil }
        return MonthlyChallengeContent.currentRound()
    }

    /// The card asks for today's round only while it is open; once played,
    /// the challenge shrinks to a chip beside the stats until tomorrow.
    private var challengeCardRound: ChallengeRound? {
        guard let round = homeChallengeRound, monthlyStore.result(for: round) == nil else { return nil }
        return round
    }

    /// Today's Mahj Minute, under Get Started (and under How to Play for
    /// a new player). Two lines in every state, so Home does not jump when a
    /// round starts.
    private func monthlyChallengeCard(_ round: ChallengeRound) -> some View {
        let run = monthlyStore.progress(for: round)
        return NavigationLink(value: AppDestination.monthlyChallenge) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.plum.opacity(0.13))
                    if let run {
                        Circle()
                            .stroke(Theme.plum.opacity(0.2), lineWidth: 3)
                            .padding(7)
                        Circle()
                            .trim(from: 0, to: Double(run.answers.count) / Double(max(round.items.count, 1)))
                            .stroke(Theme.plum, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(7)
                    } else {
                        Image(systemName: round.month.theme.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.plum)
                    }
                }
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(round.month.monthName.uppercased()) CHALLENGE · DAY\u{00A0}\(round.day)")
                        .font(.caption2.weight(.heavy))
                        .kerning(1.2)
                        .foregroundStyle(Theme.plum)
                    Text("Today's Mahj Minute")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(monthlyChallengeLine(round, run: run))
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .themedCard(corner: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.plum.opacity(0.3), lineWidth: 1)
        )
    }

    private func monthlyChallengeLine(_ round: ChallengeRound, run: MonthlyChallengeProgress?) -> String {
        if let run {
            return "\(run.answers.count) of \(round.items.count) answered today"
        }
        let score = monthlyStore.monthScore(round.monthKey)
        if score.daysPlayed == 0 {
            return "\(round.items.count) new questions a day, the same for every player"
        }
        return "\(round.items.count) questions · \(score.points)\u{00A0}\(score.points == 1 ? "point" : "points") this month"
    }

    /// Today's round is done: the month score rides beside the stats instead
    /// of holding a card, and opens the challenge.
    @ViewBuilder
    private var challengeChip: some View {
        if let round = homeChallengeRound, monthlyStore.result(for: round) != nil {
            let points = monthlyStore.monthScore(round.monthKey).points
            NavigationLink(value: AppDestination.monthlyChallenge) {
                chipBody(text: "\(points)\u{00A0}pts", icon: "calendar", color: Theme.plum)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(round.month.monthName) challenge: \(points) \(points == 1 ? "point" : "points"). Today's Mahj Minute is done.")
            .accessibilityHint("Opens the challenge")
        }
    }

    /// Members who have not picked a game night yet. One card, one tap to
    /// set it, one tap to never see it again.
    private var gameNightCard: some View {
        HStack(spacing: 12) {
            NavigationLink {
                GameNightPrepView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.plum)
                        .frame(width: 38, height: 38)
                        .background(Theme.plum.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("When's your game night?")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        Text("Pick the day and a five-minute prep built from your own misses lands before you play.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableCardStyle())
            Button {
                withAnimation(.easeOut(duration: 0.25)) { gameNightCardDismissed = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(12)
        .themedCard(corner: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.plum.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Training modes

    /// The cross-cutting practice modes. They sit above the rooms
    /// because they are what a returning player comes back FOR, but they ride
    /// in one scrolling row of compact tiles rather than three full-width
    /// cards: Home's job is still the rooms, and everything else earns its
    /// space.
    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("TRAINING")
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                // A phone fits two and a bit of these tiles and the scroll
                // indicators are off, so without a cue the visible cards read
                // as the whole offering and Timed Challenge and Fix My
                // Mistakes are never found.
                if horizontalSizeClass != .regular, !dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: 3) {
                        Text("SWIPE FOR MORE")
                            .font(.caption2.weight(.heavy))
                            .kerning(1.1)
                        Image(systemName: "chevron.compact.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(Theme.inkTertiary)
                    .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 4)
            if dynamicTypeSize.isAccessibilitySize {
                // One full-width column that grows with its text. Fixed-height
                // tiles drew over each other at the largest sizes.
                VStack(spacing: 10) {
                    trainingTiles
                }
                .padding(.horizontal, 4)
            } else if horizontalSizeClass == .regular {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    trainingTiles
                }
                .padding(.horizontal, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        trainingTiles
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var trainingTiles: some View {
        handPlayTile
        trainingTile(
            requested: .endlessPicker,
            title: "Endless\nPractice",
            icon: "infinity",
            color: Theme.jade,
            badge: nil
        ) {
            EndlessPickerView()
        }
        trainingTile(
            requested: .gameNightPrep,
            title: "Game Night\nPrep",
            icon: "person.2.fill",
            color: Theme.plum,
            badge: settings.gameNightReminderEnabled ? settings.gameNightDay.displayName : "Weekly"
        ) {
            GameNightPrepView()
        }
        trainingTile(
            requested: .timedChallenge,
            title: "Timed\nChallenge",
            icon: "timer",
            color: Theme.coral,
            badge: records.bestChallengeScore > 0 ? "Best \(records.bestChallengeScore)" : nil
        ) {
            PracticeRunView(mode: .timed)
        }
        // Only offered when there is something to fix, counted over the items
        // this runner can actually ask. An empty review session is a dead end
        // dressed up as a feature.
        let reviewable = SessionBuilder.reviewableIDs(includePro: subscriptions.isPro)
        let due = records.dueCount(among: reviewable)
        if due > 0 {
            trainingTile(
                requested: .review,
                title: "Fix My\nMistakes",
                icon: "arrow.trianglehead.counterclockwise",
                color: Theme.plum,
                badge: "\(min(due, 12)) due"
            ) {
                PracticeRunView(
                    mode: .review,
                    items: SessionBuilder.reviewSession(
                        ids: records.reviewQueue(among: reviewable),
                        includePro: subscriptions.isPro
                    )
                )
            }
        }
    }

    /// Play a Hand is the one training mode a free player can open, once a
    /// day. It is the strongest thing the membership owns, and a mode nobody
    /// has tried sells nothing; one whole hand is a real use of it rather than
    /// a teaser that stops halfway.
    @ViewBuilder
    private var handPlayTile: some View {
        let free = !subscriptions.isPro
        let available = handPlay.canPlay(isMember: subscriptions.isPro)
        if available {
            NavigationLink {
                HandPlayView()
            } label: {
                trainingTileLabel(
                    title: "Play a\nHand",
                    icon: "hand.draw.fill",
                    color: Theme.jade,
                    badge: handPlay.inProgress != nil
                        ? "Resume"
                        : (free ? "1 free today" : handPlayBadge),
                    locked: false
                )
            }
            .buttonStyle(PressableCardStyle())
        } else {
            Button { upgrade.destination = .handPlay; showPaywall = true } label: {
                trainingTileLabel(
                    title: "Play a\nHand",
                    icon: "hand.draw.fill",
                    color: Theme.jade,
                    badge: "Back tomorrow",
                    locked: true
                )
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityHint("Today's free hand is played. Unlimited with \(Membership.name)")
        }
    }

    private var handPlayBadge: String? {
        guard handPlay.handsPlayed > 0 else { return nil }
        return handPlay.bestStars > 0 ? "Best \(handPlay.bestStars)/3" : "\(handPlay.handsPlayed) played"
    }

    /// A compact training tile. Locked for free players: tapping opens the
    /// paywall instead of the mode, and the tile says so before it is tapped.
    @ViewBuilder
    private func trainingTile<Destination: View>(
        requested: AppDestination,
        title: String,
        icon: String,
        color: Color,
        badge: String?,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        let locked = !subscriptions.isPro
        if locked {
            Button { upgrade.destination = requested; showPaywall = true } label: {
                trainingTileLabel(title: title, icon: icon, color: color, badge: badge, locked: true)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityHint("Included with \(Membership.name)")
        } else {
            NavigationLink { destination() } label: {
                trainingTileLabel(title: title, icon: icon, color: color, badge: badge, locked: false)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    private func trainingTileLabel(title: String, icon: String, color: Color, badge: String?, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
                Spacer(minLength: 0)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.gold)
                }
            }
            Spacer(minLength: 0)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
            } else {
                Text(locked ? Membership.name : " ")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.goldText)
            }
        }
        .padding(12)
        .modifier(TrainingTileFrame(
            fullWidth: horizontalSizeClass == .regular || dynamicTypeSize.isAccessibilitySize,
            fixedHeight: !dynamicTypeSize.isAccessibilitySize
        ))
        .themedCard(corner: 16)
    }

    // MARK: - Rooms

    private var roomsHeading: some View {
        HStack {
            Text("THE ROOMS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }

    /// Progress is a ring, not a sentence. "2 of 3 done · 2 free, 1 with Mahj+"
    /// was three facts nobody asked for on a card whose job is to be a door.
    ///
    /// The ring measures MASTERY, not drills opened. Counting opened drills
    /// rewards tapping: finish every drill once, badly, and the room reads as
    /// done forever. Counting questions the player has answered right twice
    /// running rewards the thing the app is for. The denominator still counts
    /// only what this player can actually reach, because a ring that can never
    /// close is a nag dressed up as progress.
    /// Name and Mahj+ badge side by side, or stacked at accessibility sizes.
    private var titleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 6))
    }

    private func roomCard(_ room: Room) -> some View {
        let locked = !room.isFree && !subscriptions.isPro
        let highlighted = highlightedRoomID == room.id
        let mastery = records.mastery(for: room, isMember: subscriptions.isPro)
        return NavigationLink {
            RoomView(room: room)
        } label: {
            HStack(spacing: 14) {
                // At accessibility sizes the icon and a badge beside the name
                // left the name a word's width, and it broke mid-word.
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: room.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(room.accent)
                        .frame(width: 48, height: 48)
                        .background(room.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 3) {
                    titleLayout {
                        Text(room.name)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        if locked {
                            PlusBadge()
                        }
                    }
                    Text(room.tagline)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.gold)
                } else {
                    MasteryRing(mastery: mastery, color: room.accent)
                }
            }
            .padding(14)
            .themedCard()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(highlighted ? room.accent : Color.clear, lineWidth: 2.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint(locked
            ? "Locked. \(room.drills.count) drills, included with \(Membership.name)"
            : "\(mastery.level.title). \(mastery.known) of \(mastery.total) questions solid")
        .id(room.id)
    }

    private var upgradeCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get \(Membership.name)")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Coached practice hands as often as you want, Game Night Prep, endless modes, and \(lockedDrillCount) more drills")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(12)
            .themedCard(corner: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
        .padding(.top, 2)
    }

    private var lockedDrillCount: Int {
        DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount }
    }

    private var disclaimerFooter: some View {
        Text("Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.")
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

/// Room mastery at a glance: a ring that fills as the room's questions start
/// holding, with the level word underneath so the ring means something more
/// than "some of a thing".
struct MasteryRing: View {
    let mastery: RoomMastery
    var color: Color

    /// 9pt at the default size, as designed, and growing a little with the
    /// player's text size. Capped at 12pt: any wider and "Learning" took the
    /// width from the room name beside it ("The / Charleston / Room").
    @ScaledMetric(relativeTo: .caption2) private var captionSize: CGFloat = 9

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: mastery.fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mastery.fraction)
                switch mastery.level {
                case .sharp:
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(color)
                case .untouched, .learning where mastery.known == 0:
                    // An empty ring already says nothing has been learned here.
                    // Printing a 0 inside it as well is the same fact twice,
                    // and it reads as a score rather than a starting point.
                    EmptyView()
                default:
                    Text("\(Int((mastery.fraction * 100).rounded()))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.inkSecondary)
                        .monospacedDigit()
                }
            }
            .frame(width: 32, height: 32)
            Text(mastery.level == .untouched ? "New" : mastery.level.title)
                .font(.system(size: min(captionSize, 12), weight: .semibold))
                .foregroundStyle(Theme.inkTertiary)
                .fixedSize()
        }
        .frame(minWidth: 46)
        .accessibilityHidden(true)
    }
}

extension DrillKind {
    var symbol: String {
        switch self {
        case .flashcards: return "rectangle.stack.fill"
        case .quiz: return "questionmark.circle.fill"
        case .handMatch: return "square.grid.3x3.fill"
        case .charleston: return "arrow.left.arrow.right"
        }
    }

    var unitName: String {
        switch self {
        case .flashcards: return "cards"
        case .quiz: return "questions"
        case .handMatch: return "racks"
        case .charleston: return "deals"
        }
    }
}

/// A training tile is a fixed 118pt card in the phone's scrolling row and the
/// iPad grid, and grows with its text at accessibility sizes.
private struct TrainingTileFrame: ViewModifier {
    let fullWidth: Bool
    let fixedHeight: Bool

    func body(content: Content) -> some View {
        if fixedHeight {
            content
                .frame(width: fullWidth ? nil : 128, height: 118, alignment: .leading)
                .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
        } else {
            content.frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
    }
}
