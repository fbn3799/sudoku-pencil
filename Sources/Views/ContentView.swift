import SwiftUI

struct ContentView: View {
    @StateObject private var board = SudokuBoard(difficulty: .medium)
    @StateObject private var noteMode = NoteModeState()
    @StateObject private var historyStore = GameHistoryStore()
    @State private var showCongrats = false
    @State private var showHistory = false
    @State private var showSettings = false
    @AppStorage("app_color_scheme") private var colorSchemePreference: String = "system"

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let side = gridSide(for: geo.size, landscape: isLandscape)
            let cs = side / 9

            ZStack {
                // Grid — always dead center of screen
                gridArea(cellSize: cs)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Controls positioned around the grid
                if isLandscape {
                    // Toolbar top-right
                    VStack {
                        toolbarButtons
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    // Number pad / note panel right of grid
                    HStack {
                        Spacer()
                        controlsPanel(landscape: true)
                            .padding(.trailing, 24)
                    }
                } else {
                    VStack {
                        toolbarButtons
                            .padding(.horizontal)
                            .padding(.top, 8)

                        Spacer()

                        controlsPanel(landscape: false)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }
                }

                // Note mode edge glow
                if noteMode.isActive {
                    Rectangle()
                        .stroke(noteMode.selectedColor.opacity(0.3), lineWidth: 4)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
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

    // MARK: - Grid sizing

    private func gridSide(for size: CGSize, landscape: Bool) -> CGFloat {
        // Take the smaller dimension, leave room for controls
        if landscape {
            return size.height - 60
        } else {
            return min(size.width - 32, size.height - 200)
        }
    }

    // MARK: - Grid

    private func gridArea(cellSize: CGFloat) -> some View {
        let side = cellSize * 9
        return ZStack {
            SudokuGridView(board: board, cellSize: cellSize)

            PencilInputOverlay(
                board: board,
                noteMode: noteMode,
                cellSize: cellSize,
                gridOrigin: .zero
            )
            .frame(width: side, height: side)
            .allowsHitTesting(true)
        }
        .frame(width: side, height: side)
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 20) {
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
                Image(systemName: "slider.horizontal.3").font(.title3)
            }

            Spacer()

            Button {
                noteMode.isActive ? noteMode.deactivate() : noteMode.activate()
            } label: {
                Image(systemName: noteMode.isActive ? "pencil.circle.fill" : "pencil.circle")
                    .font(.title2)
                    .foregroundColor(noteMode.isActive ? noteMode.selectedColor : .secondary)
            }

            Button { saveAndNewGame() } label: {
                Image(systemName: "arrow.triangle.2.circlepath").font(.title3)
            }

            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath").font(.title3)
            }

            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.title3)
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private func controlsPanel(landscape: Bool) -> some View {
        if noteMode.isActive {
            NoteModePanel(noteMode: noteMode) {
                noteMode.deactivate()
                noteMode.activate()
            }
        } else {
            NumberPadView(board: board, axis: landscape ? .vertical : .horizontal)
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
