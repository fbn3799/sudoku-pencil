import SwiftUI

struct ContentView: View {
    @StateObject private var board = SudokuBoard(difficulty: .medium)
    @State private var showDifficultyPicker = false
    @State private var showCongrats = false

    // Adaptive cell size for iPad
    private var cellSize: CGFloat {
        let screenMin = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return min((screenMin - 120) / 9, 72)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Sudoku grid
                SudokuGridView(board: board, cellSize: cellSize)

                // Pencil drawing area (appears when cell selected)
                PencilInputOverlay(board: board)

                // Number pad (finger fallback)
                NumberPadView(board: board)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Sudoku ✏️")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(SudokuBoard.Difficulty.allCases, id: \.self) { diff in
                            Button(diff.rawValue.capitalized) {
                                let newBoard = SudokuBoard(difficulty: diff)
                                replaceBoard(with: newBoard)
                            }
                        }
                    } label: {
                        Label("Difficulty", systemImage: "slider.horizontal.3")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        board.newGame()
                    } label: {
                        Label("New Game", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .onChange(of: board.isSolved) { _, solved in
                if solved { showCongrats = true }
            }
            .alert("🎉 Congratulations!", isPresented: $showCongrats) {
                Button("New Game") { board.newGame() }
                Button("OK", role: .cancel) {}
            } message: {
                Text("You solved the puzzle!")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func replaceBoard(with newBoard: SudokuBoard) {
        // SwiftUI workaround: copy state
        board.cells = newBoard.cells
        board.selectedCell = nil
    }
}

#Preview {
    ContentView()
}
