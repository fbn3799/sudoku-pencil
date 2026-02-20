import SwiftUI

struct ContentView: View {
    @StateObject private var board = SudokuBoard(difficulty: .medium)
    @StateObject private var noteMode = NoteModeState()
    @StateObject private var historyStore = GameHistoryStore()
    @State private var showCongrats = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showNumpad = false
    @AppStorage("app_color_scheme") private var colorSchemePreference: String = "system"

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let side = gridSide(for: geo.size, landscape: isLandscape)
            let cs = side / 9

            ZStack {
                // Grid — always dead center
                gridArea(cellSize: cs)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Controls
                VStack {
                    toolbarButtons
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer()

                    if showNumpad || noteMode.isActive {
                        controlsPanel(landscape: isLandscape)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .animation(.easeInOut(duration: 0.25), value: showNumpad)
            .animation(.easeInOut(duration: 0.25), value: noteMode.isActive)
        }
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
            SettingsView(
                colorSchemePreference: $colorSchemePreference,
                board: board,
                onNewGame: saveAndNewGame
            )
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    // MARK: - Grid sizing

    private func gridSide(for size: CGSize, landscape: Bool) -> CGFloat {
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

    // MARK: - Toolbar (settings left, actions right)

    private var toolbarButtons: some View {
        HStack(spacing: 20) {
            // Settings (left)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.title3)
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

            // Numpad toggle
            Button {
                showNumpad.toggle()
                board.numpadActive = showNumpad
                if !showNumpad { board.clearAllHighlights() }
            } label: {
                Image(systemName: showNumpad ? "number.circle.fill" : "number.circle")
                    .font(.title2)
                    .foregroundColor(showNumpad ? .blue : .secondary)
            }

            // New game
            Button { saveAndNewGame() } label: {
                Image(systemName: "arrow.triangle.2.circlepath").font(.title3)
            }

            // History
            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath").font(.title3)
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
        } else if showNumpad {
            NumberPadView(board: board, axis: .horizontal)
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
}

#Preview {
    ContentView()
}
