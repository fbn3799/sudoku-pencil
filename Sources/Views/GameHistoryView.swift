import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var historyStore: GameHistoryStore
    let onRestore: (SavedGame) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.games.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No saved games yet")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(historyStore.games) { game in
                            Button {
                                onRestore(game)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(game.dateFormatted)
                                            .font(.headline)
                                        Text("\(game.difficulty.capitalized) • \(game.progress)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.uturn.backward")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                            .tint(.primary)
                        }
                        .onDelete { offsets in
                            historyStore.remove(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
