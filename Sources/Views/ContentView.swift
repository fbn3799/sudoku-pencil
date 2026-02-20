import SwiftUI

struct ContentView: View {
    @StateObject private var board = SudokuBoard(difficulty: .medium)
    @StateObject private var noteMode = NoteModeState()
    @StateObject private var historyStore = GameHistoryStore()
    @State private var showCongrats = false
    @State private var showHistory = false
    @State private var showSettings = false
    @AppStorage("app_color_scheme") private var colorSchemePreference: String = "system"

    private var cellSize: CGFloat {
        let screenMin = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return min((screenMin - 120) / 9, 72)
    }

    var body: some View {
        ZStack {
            // Note mode visual indicator: subtle border glow.
            if noteMode.isActive {
                Color.clear
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(noteMode.selectedColor.opacity(0.3), lineWidth: 4)
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                // Top bar
                HStack {
                    // Difficulty menu
                    Menu {
                        ForEach(SudokuBoard.Difficulty.allCases, id: \.self) { diff in
                            Button {
                                saveCurrentGame()
                                board.difficulty = diff
                                board.newGame()
                            } label: {
                                Label(diff.rawValue.capitalized, systemImage: difficultyIcon(diff))
                            }
                        }
                    } label: {
                        Label("Difficulty", systemImage: "slider.horizontal.3")
                            .font(.title3)
                    }

                    Spacer()

                    // Note mode toggle
                    Button {
                        if noteMode.isActive {
                            noteMode.deactivate()
                        } else {
                            noteMode.activate()
                        }
                    } label: {
                        Image(systemName: noteMode.isActive ? "pencil.circle.fill" : "pencil.circle")
                            .font(.title2)
                            .foregroundColor(noteMode.isActive ? noteMode.selectedColor : .secondary)
                    }

                    // New game
                    Button {
                        saveCurrentGame()
                        board.newGame()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                    }

                    // History
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                    }

                    // Settings
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Grid with pencil overlay
                ZStack {
                    SudokuGridView(board: board, cellSize: cellSize)

                    GeometryReader { _ in
                        PencilInputOverlay(
                            board: board,
                            noteMode: noteMode,
                            cellSize: cellSize,
                            gridOrigin: .zero
                        )
                    }
                    .frame(width: cellSize * 9, height: cellSize * 9)
                    .allowsHitTesting(true)
                }

                // Note mode panel or number pad
                if noteMode.isActive {
                    NoteModePanel(noteMode: noteMode) {
                        // Erase all notes — handled by the overlay coordinator.
                        // For now just deactivate and reactivate to clear canvas.
                        noteMode.deactivate()
                        noteMode.activate()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    NumberPadView(board: board)
                }

                Spacer()
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.25), value: noteMode.isActive)
        .onChange(of: board.isSolved) { _, solved in
            if solved { showCongrats = true }
        }
        .alert("🎉 Congratulations!", isPresented: $showCongrats) {
            Button("New Game") {
                saveCurrentGame()
                board.newGame()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("You solved the puzzle!")
        }
        .sheet(isPresented: $showHistory) {
            GameHistoryView(historyStore: historyStore) { saved in
                board.restore(from: saved)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(colorSchemePreference: $colorSchemePreference)
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func saveCurrentGame() {
        let saved = board.toSavedGame()
        // Only save if there's any progress.
        let hasProgress = saved.playerValues.contains(where: { $0 != nil })
        if hasProgress {
            historyStore.save(game: saved)
        }
    }

    private func difficultyIcon(_ diff: SudokuBoard.Difficulty) -> String {
        switch diff {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
}

#Preview {
    ContentView()
}
