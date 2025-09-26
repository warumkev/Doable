import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("Coming soon — this will show Momentum, streaks and history.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StatisticsView()
}
