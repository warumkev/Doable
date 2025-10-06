import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey("privacy.intro"))
                        .font(.body)

                    Text(LocalizedStringKey("privacy.data_storage"))

                    Text(LocalizedStringKey("privacy.tracking"))

                    Text(LocalizedStringKey("privacy.sync_note"))

                    Text(LocalizedStringKey("privacy.contact"))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("settings.privacy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("disappointment.ok")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PrivacyView()
}
