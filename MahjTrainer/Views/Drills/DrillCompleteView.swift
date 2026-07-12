import SwiftUI
import StoreKit

struct DrillCompleteView: View {
    let drill: Drill
    let score: Int?
    let total: Int

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showEnjoymentGate = false
    @State private var recorded = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.felt)
            Text("Drill complete!")
                .font(.title.bold())
            if let score {
                Text("\(score) of \(total) right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(total) cards reviewed")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(progress.streakCount)-day streak")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.cardBackground, in: Capsule())
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !recorded else { return }
            recorded = true
            progress.recordSession(drillID: drill.id)
            if progress.shouldShowEnjoymentGate() {
                showEnjoymentGate = true
            }
        }
        .alert("Enjoying Mahj Trainer?", isPresented: $showEnjoymentGate) {
            Button("Yes!") { requestReview() }
            Button("Not really", role: .cancel) {}
        } message: {
            Text("You've finished 3 drills. Nice streak!")
        }
    }
}
