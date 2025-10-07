import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct SettingsView: View {
    @AppStorage("settings.theme") private var theme: String = "system"
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("settings.hasAskedNotificationPermission") private var hasAskedNotificationPermission: Bool = false
    @AppStorage("settings.prefillSuggestions") private var prefillSuggestions: Bool = false
    @AppStorage("settings.defaultTimerMinutes") private var defaultTimerMinutes: Int = 5
    @AppStorage("settings.iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @State private var showICloudRestartAlert: Bool = false

    private let timerOptions = [1, 3, 5, 10, 15, 20, 25, 30]

    // Todos provided by parent for export
    var todos: [Todo] = []

    // Export state
    @State private var exportData: Data? = nil
    @State private var isExporting: Bool = false
    @State private var exportError: String? = nil
    @State private var showExportSuccess: Bool = false
    // Import state
    @State private var isImporting: Bool = false
    @State private var importError: String? = nil
    @State private var showImportSuccess: Bool = false

    @Environment(\.modelContext) private var modelContext
    // Reset state
    @State private var isResetConfirmPresented: Bool = false
    @State private var showResetSuccess: Bool = false
    @State private var isPrivacyPresented: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(LocalizedStringKey("settings.general"))) {
                    Picker(selection: $theme) {
                        Text(LocalizedStringKey("settings.theme.system")).tag("system")
                        Text(LocalizedStringKey("settings.theme.light")).tag("light")
                        Text(LocalizedStringKey("settings.theme.dark")).tag("dark")
                    } label: {
                        Text(LocalizedStringKey("settings.theme"))
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: theme) { _, newTheme in
                    func applyStyle(_ style: UIUserInterfaceStyle) {
                        // Find a window from connected scenes in a way that avoids the deprecated API
                        for scene in UIApplication.shared.connectedScenes {
                            if let ws = scene as? UIWindowScene {
                                if let win = ws.windows.first {
                                    win.overrideUserInterfaceStyle = style
                                    break
                                }
                            }
                        }
                    }

                    switch newTheme {
                    case "light":
                        applyStyle(.light)
                    case "dark":
                        applyStyle(.dark)
                    default:
                        applyStyle(.unspecified)
                    }
                }

                Section(header: Text(LocalizedStringKey("settings.notifications"))) {
                    Toggle(LocalizedStringKey("settings.haptics"), isOn: $hapticsEnabled)
                    Toggle(LocalizedStringKey("settings.sound"), isOn: $soundEnabled)

                    Toggle(LocalizedStringKey("settings.push_notifications"), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                // Request permission when user enables the toggle
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                    DispatchQueue.main.async {
                                        notificationsEnabled = granted
                                        hasAskedNotificationPermission = true
                                    }
                                }
                            } else {
                                // The user turned off in-app toggle; don't revoke system permission here.
                                // Keep the flag updated so UI can show helpful guidance.
                                hasAskedNotificationPermission = true
                            }
                        }

                    // If notifications are disabled but we previously asked, offer a quick link to system Settings
                    if !notificationsEnabled && hasAskedNotificationPermission {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(LocalizedStringKey("settings.push_notifications_open_settings"))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section(header: Text(LocalizedStringKey("settings.timer_defaults"))) {
                    Picker(selection: $defaultTimerMinutes) {
                        ForEach(timerOptions, id: \.self) { minutes in
                            Text(String(format: NSLocalizedString("settings.default_timer_minutes_format", comment: "minutes format"), minutes)).tag(minutes)
                        }
                    } label: {
                        Text(LocalizedStringKey("settings.default_timer_minutes"))
                    }
                }

                Section(header: Text(LocalizedStringKey("settings.todos"))) {
                    Toggle(LocalizedStringKey("settings.prefill_suggestions"), isOn: $prefillSuggestions)
                    Text(LocalizedStringKey("settings.prefill_suggestions_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text(LocalizedStringKey("settings.data"))) {
                    Toggle(LocalizedStringKey("settings.iCloud_sync"), isOn: $iCloudSyncEnabled)
                        .onChange(of: iCloudSyncEnabled) { _, _ in
                            // Changing the ModelContainer backend requires recreating
                            // the ModelContainer. Inform the user to restart the app.
                            showICloudRestartAlert = true
                        }
                    Text(LocalizedStringKey("settings.iCloud_sync_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        prepareExport()
                    } label: {
                        Text(LocalizedStringKey("settings.export"))
                            .foregroundColor(.primary)
                    }
                    .fileExporter(isPresented: $isExporting, document: ExportDocument(data: exportData ?? Data()), contentType: .json, defaultFilename: "doable-export") { result in
                        switch result {
                        case .success:
                            showExportSuccess = true
                        case .failure(let err):
                            exportError = err.localizedDescription
                        }
                    }
                    Button {
                        isImporting = true
                    } label: {
                        Text(LocalizedStringKey("settings.import"))
                            .foregroundColor(.primary)
                    }
                    .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                        switch result {
                        case .success(let url):
                            do {
                                let didStart = url.startAccessingSecurityScopedResource()
                                defer {
                                    if didStart { url.stopAccessingSecurityScopedResource() }
                                }

                                let data = try Data(contentsOf: url)
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                let items = try decoder.decode([ExportTodo].self, from: data)
                                for item in items {
                                    let t = Todo(title: item.title)
                                    t.isCompleted = item.isCompleted
                                    t.createdAt = item.createdAt
                                    modelContext.insert(t)
                                }
                                showImportSuccess = true
                            } catch {
                                let msg = error.localizedDescription.lowercased()
                                if msg.contains("permission") || msg.contains("not permitted") || msg.contains("access") {
                                    importError = NSLocalizedString("settings.import_permission_help", comment: "Instruction to grant access to Files/iCloud")
                                } else {
                                    importError = error.localizedDescription
                                }
                            }
                        case .failure(let err):
                            importError = err.localizedDescription
                        }
                    }
                    Button(role: .destructive) {
                        isResetConfirmPresented = true
                    } label: {
                        Text(LocalizedStringKey("settings.reset_data"))
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text(LocalizedStringKey("settings.about"))) {
                    HStack {
                        Text(LocalizedStringKey("settings.version"))
                        .foregroundColor(.secondary)
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2510.07")
                            .foregroundColor(.secondary)
                    }

                    Button(LocalizedStringKey("settings.send_feedback")) {
                        if let url = URL(string: "mailto:kevintamme@icloud.com?subject=Doable%20Feedback") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.secondary)

                    Button(LocalizedStringKey("settings.privacy")) {
                        isPrivacyPresented = true
                    }
                    .foregroundColor(.secondary)

                    .sheet(isPresented: $isPrivacyPresented) {
                        PrivacyView()
                    }
                    HStack {
                        Spacer()
                        Text("© 2025 Kevin Tamme - Doable")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizedStringKey("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        // Alerts: Export/Import/Reset feedback
        .alert(LocalizedStringKey("settings.reset_confirm_title"), isPresented: $isResetConfirmPresented) {
            Button(LocalizedStringKey("settings.reset_confirm_cancel"), role: .cancel) {}
            Button(LocalizedStringKey("settings.reset_confirm_confirm"), role: .destructive) {
                // Perform reset: delete all todos known to the parent
                for t in todos {
                    modelContext.delete(t)
                }
                showResetSuccess = true
            }
        } message: {
            Text(LocalizedStringKey("settings.reset_confirm_message"))
        }
        .alert(LocalizedStringKey("settings.export_success"), isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        }
        .alert(LocalizedStringKey("settings.import_success"), isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        }
        .alert(LocalizedStringKey("settings.reset_success"), isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) {}
        }
        .alert(isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Alert(title: Text(LocalizedStringKey("settings.export_failure")), message: Text(exportError ?? ""), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Alert(title: Text(LocalizedStringKey("settings.import_failure")), message: Text(importError ?? ""), dismissButton: .default(Text("OK")))
        }
        .alert(LocalizedStringKey("settings.restart_required_title"), isPresented: $showICloudRestartAlert) {
            Button(LocalizedStringKey("disappointment.ok"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("settings.restart_required_message"))
        }
    }
}

// Small Codable representation for export
private struct ExportTodo: Codable {
    let title: String
    let isCompleted: Bool
    let createdAt: Date
}

/// A simple FileDocument wrapper so we can use SwiftUI's FileExporter API with raw data
private struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let d = configuration.file.regularFileContents {
            data = d
        } else {
            data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: data)
    }
}

private extension SettingsView {
    func prepareExport() {
        // Build an array of ExportTodo
        let exportItems = todos.map { ExportTodo(title: $0.title, isCompleted: $0.isCompleted, createdAt: $0.createdAt) }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode(exportItems)
            exportData = json
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
}
