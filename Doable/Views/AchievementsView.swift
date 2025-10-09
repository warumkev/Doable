import SwiftUI

struct AchievementsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(LocalizedStringKey("achievements.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                Spacer()
                Text(LocalizedStringKey("achievements.empty"))
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedStringKey("achievements.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AchievementsView()
}
