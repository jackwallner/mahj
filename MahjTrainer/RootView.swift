import SwiftUI

struct RootView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var showOnboarding = false

    var body: some View {
        HomeView()
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .onAppear {
                showOnboarding = !progress.hasOnboarded
            }
    }
}
