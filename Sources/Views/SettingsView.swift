import SwiftUI

struct SettingsView: View {
    @Binding var colorSchemePreference: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $colorSchemePreference) {
                        Label("System", systemImage: "circle.lefthalf.filled")
                            .tag("system")
                        Label("Light", systemImage: "sun.max")
                            .tag("light")
                        Label("Dark", systemImage: "moon")
                            .tag("dark")
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
