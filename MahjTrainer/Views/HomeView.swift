import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsHeader
                    ForEach(DrillLibrary.rooms) { room in
                        roomCard(room)
                    }
                    disclaimerFooter
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("Mahj Trainer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 12) {
            statTile(value: "\(progress.streakCount)", label: "Day streak", icon: "flame.fill", color: .orange)
            statTile(value: "\(progress.totalSessions)", label: "Drills done", icon: "checkmark.seal.fill", color: Theme.felt)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
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
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                RoomView(room: room)
            } label: {
                roomCardBody(room, locked: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func roomCardBody(_ room: Room, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.felt.opacity(locked ? 0.5 : 1))
                    .frame(width: 52, height: 52)
                Image(systemName: room.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.headline)
                Text(room.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.gold)
            } else {
                progressRing(progress.roomProgress(room))
            }
        }
        .padding(14)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func progressRing(_ fraction: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Theme.felt.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.felt, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if fraction >= 1 {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.felt)
            }
        }
        .frame(width: 28, height: 28)
    }

    private var disclaimerFooter: some View {
        Text("Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}
