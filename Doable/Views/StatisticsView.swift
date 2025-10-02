import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text(LocalizedStringKey("statistics.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text(LocalizedStringKey("statistics.coming_soon"))
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
