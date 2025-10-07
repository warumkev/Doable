import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(LocalizedStringKey("privacy.intro"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.bottom, 4)

                    Group {
                        Text(LocalizedStringKey("privacy.section_data"))
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text(LocalizedStringKey("privacy.data_storage"))
                            .font(.body)
                    }

                    Group {
                        Text(LocalizedStringKey("privacy.section_tracking"))
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text(LocalizedStringKey("privacy.tracking"))
                            .font(.body)
                    }

                    Group {
                        Text(LocalizedStringKey("privacy.section_sync"))
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text(LocalizedStringKey("privacy.sync_note"))
                            .font(.body)
                    }

                    Group {
                        Text(LocalizedStringKey("privacy.section_contact"))
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text(LocalizedStringKey("privacy.contact"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
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
