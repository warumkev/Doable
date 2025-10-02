import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("Coming soon — this will show settings.")
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
