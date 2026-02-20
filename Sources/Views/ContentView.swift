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
            let gridSide = gridSize(for: geo.size, landscape: isLandscape)

            if isLandscape {
                HStack(spacing: 0) {
                    // Grid centered in its half
                    gridArea(cellSize: gridSide / 9)
                        .frame(width: geo.size.width * 0.6)

                    // Controls on the right
                    VStack(spacing: 20) {
                        toolbarButtons
                        Spacer()
                        controlsPanel(landscape: true)
                        Spacer()
                    }
                    .frame(width: geo.size.width * 0.4)
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    toolbarButtons
                        .padding(.horizontal)
                    Spacer()
                    gridArea(cellSize: gridSide / 9)
                    Spacer()
                    controlsPanel(landscape: false)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
            }
        }
        .overlay {
            // Note mode edge glow
            if noteMode.isActive {
                Rectangle()
                    .stroke(noteMode.selectedColor.opacity(0.3), lineWidth: 4)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
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

    // MARK: - Grid size calculation

    private func gridSize(for size: CGSize, landscape: Bool) -> CGFloat {
        if landscape {
            // Use available height minus padding
            let available = size.height - 40
            return min(available, size.width * 0.55)
        } else {
            // Use width minus padding, capped
            return min(size.width - 32, size.height * 0.6)
        }
    }

    // MARK: - Grid + overlay, always a centered perfect square

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

    // MARK: - Toolbar buttons

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
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
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
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
            }

            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
            }

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
        }
    }

    // MARK: - Bottom/side controls

    @ViewBuilder
    private func controlsPanel(landscape: Bool) -> some View {
        if noteMode.isActive {
            NoteModePanel(noteMode: noteMode) {
                noteMode.deactivate()
                noteMode.activate()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
