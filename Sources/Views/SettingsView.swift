import SwiftUI

struct SettingsView: View {
    @Binding var colorSchemePreference: String
    @ObservedObject var board: SudokuBoard
    let onNewGame: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Difficulty") {
                    ForEach(SudokuBoard.Difficulty.allCases, id: \.self) { diff in
                        Button {
                            board.difficulty = diff
                            onNewGame()
                            dismiss()
                        } label: {
                            HStack {
                                Text(diff.rawValue.capitalized)
                                    .foregroundColor(.primary)
                                Spacer()
                                if board.difficulty == diff {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Color Scheme", selection: $colorSchemePreference) {
                        Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                        Label("Light", systemImage: "sun.max").tag("light")
                        Label("Dark", systemImage: "moon").tag("dark")
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
