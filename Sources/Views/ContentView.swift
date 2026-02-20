import SwiftUI

struct ContentView: View {
    @StateObject private var board = SudokuBoard(difficulty: .medium)
    @StateObject private var noteMode = NoteModeState()
    @StateObject private var historyStore = GameHistoryStore()
    @State private var showCongrats = false
    @State private var showHistory = false
    @State private var showSettings = false
    @AppStorage("app_color_scheme") private var colorSchemePreference: String = "system"
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    private var isLandscape: Bool { vSize == .compact }

    private var cellSize: CGFloat {
        if isLandscape {
            let screenH = UIScreen.main.bounds.height
            return min((screenH - 80) / 9, 64)
        } else {
            let screenW = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            return min((screenW - 60) / 9, 72)
        }
    }

    var body: some View {
        ZStack {
            // Note mode edge indicator
            if noteMode.isActive {
                Color.clear
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(noteMode.selectedColor.opacity(0.3), lineWidth: 4)
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .animation(.easeInOut(duration: 0.25), value: noteMode.isActive)
        .onChange(of: board.isSolved) { _, solved in
            if solved { showCongrats = true }
        }
        .alert("🎉 Congratulations!", isPresented: $showCongrats) {
            Button("New Game") { saveAndNewGame() }
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

    // MARK: - Portrait

    private var portraitLayout: some View {
        VStack(spacing: 16) {
            toolbar

            Spacer()

            gridWithOverlay

            Spacer()

            bottomControls
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: 20) {
            // Left side: grid
            VStack {
                Spacer()
                gridWithOverlay
                Spacer()
            }

            // Right side: controls stacked vertically
            VStack(spacing: 16) {
                toolbar

                Spacer()

                if noteMode.isActive {
                    NoteModePanel(noteMode: noteMode) {
                        noteMode.deactivate()
                        noteMode.activate()
                    }
                } else {
                    NumberPadView(board: board, axis: .vertical)
                }

                Spacer()
            }
            .frame(maxWidth: 160)
        }
        .padding()
    }

    // MARK: - Shared Components

    private var gridWithOverlay: some View {
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
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Difficulty
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
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
            }

            Spacer()

            // Note mode
            Button {
                noteMode.isActive ? noteMode.deactivate() : noteMode.activate()
            } label: {
                Image(systemName: noteMode.isActive ? "pencil.circle.fill" : "pencil.circle")
                    .font(.title2)
                    .foregroundColor(noteMode.isActive ? noteMode.selectedColor : .secondary)
            }

            // New game
            Button { saveAndNewGame() } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
            }

            // History
            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
            }

            // Settings
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
        }
    }

    private var bottomControls: some View {
        Group {
            if noteMode.isActive {
                NoteModePanel(noteMode: noteMode) {
                    noteMode.deactivate()
                    noteMode.activate()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                NumberPadView(board: board, axis: .horizontal)
            }
        }
    }

    // MARK: - Helpers

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func saveAndNewGame() {
        saveCurrentGame()
        board.newGame()
    }

    private func saveCurrentGame() {
        let saved = board.toSavedGame()
        if saved.playerValues.contains(where: { $0 != nil }) {
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
