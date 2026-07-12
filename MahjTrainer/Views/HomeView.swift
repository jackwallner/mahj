import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    statsHeader
                    VStack(spacing: 14) {
                        ForEach(DrillLibrary.rooms) { room in
                            roomCard(room)
                        }
                    }
                    disclaimerFooter
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .toolbar {
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .tint(Theme.jade)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mahj Trainer")
                .font(Theme.display(34))
                .foregroundStyle(Theme.ink)
            Text("Your seat at the table.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private var statsHeader: some View {
        HStack(spacing: 12) {
            statTile(value: "\(progress.streakCount)", label: "Day streak", icon: "flame.fill", color: Theme.coral)
            statTile(value: "\(progress.totalSessions)", label: "Drills done", icon: "checkmark.seal.fill", color: Theme.jade)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .themedCard(corner: 16)
    }

    @ViewBuilder
    private func roomCard(_ room: Room) -> some View {
        let locked = !room.isFree && !subscriptions.isPro
        if locked {
            Button {
                showPaywall = true
            } label: {
                roomCardBody(room, locked: true)
            }
            .buttonStyle(PressableCardStyle())
        } else {
            NavigationLink {
                RoomView(room: room)
            } label: {
                roomCardBody(room, locked: false)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    private func roomCardBody(_ room: Room, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(room.accent.opacity(locked ? 0.10 : 0.16))
                    .frame(width: 56, height: 56)
                Image(systemName: room.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(locked ? room.accent.opacity(0.55) : room.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(Theme.display(19, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(room.tagline)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            if locked {
                Text("PRO")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.gold.opacity(0.15), in: Capsule())
            } else {
                progressRing(progress.roomProgress(room), accent: room.accent)
            }
        }
        .padding(16)
        .themedCard()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }

    private func progressRing(_ fraction: Double, accent: Color) -> some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.18), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if fraction >= 1 {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                    .foregroundStyle(accent)
            }
        }
        .frame(width: 30, height: 30)
    }

    private var disclaimerFooter: some View {
        Text("Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.")
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}
