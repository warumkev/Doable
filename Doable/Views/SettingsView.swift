import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text(LocalizedStringKey("settings.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text(LocalizedStringKey("settings.coming_soon"))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StatisticsView()
}
