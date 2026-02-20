import Foundation

/// Represents a single cell on the Sudoku board.
struct SudokuCell: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let col: Int
    /// The correct solution value (1-9).
    let solution: Int
    /// Whether this cell was pre-filled (given clue).
    let isGiven: Bool
    /// The player's current answer (nil = empty).
    var playerValue: Int?
    /// Whether the cell is currently selected.
    var isSelected: Bool = false

    var isEmpty: Bool { !isGiven && playerValue == nil }
    var isCorrect: Bool { playerValue == solution }
    var isFilled: Bool { isGiven || playerValue != nil }
    var displayValue: Int? { isGiven ? solution : playerValue }
}

/// Full 9×9 Sudoku board with puzzle generation.
class SudokuBoard: ObservableObject {
    @Published var cells: [[SudokuCell]]
    @Published var selectedCell: (row: Int, col: Int)?
    let difficulty: Difficulty

    enum Difficulty: String, CaseIterable {
        case easy, medium, hard

        var cellsToRemove: Int {
            switch self {
            case .easy:   return 35
            case .medium: return 45
            case .hard:   return 55
            }
        }
    }

    init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
        self.cells = Array(repeating: Array(repeating:
            SudokuCell(row: 0, col: 0, solution: 0, isGiven: false), count: 9), count: 9)
        generatePuzzle()
    }

    // MARK: - Puzzle Generation

    private func generatePuzzle() {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)

        // Determine which cells are given (not removed).
        var removed = Set<Int>()
        let totalCells = 81
        while removed.count < difficulty.cellsToRemove {
            removed.insert(Int.random(in: 0..<totalCells))
        }

        var newCells: [[SudokuCell]] = []
        for r in 0..<9 {
            var row: [SudokuCell] = []
            for c in 0..<9 {
                let idx = r * 9 + c
                let isGiven = !removed.contains(idx)
                row.append(SudokuCell(
                    row: r, col: c,
                    solution: grid[r][c],
                    isGiven: isGiven,
                    playerValue: isGiven ? nil : nil
                ))
            }
            newCells.append(row)
        }
        cells = newCells
    }

    private func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 {
                    for n in (1...9).shuffled() {
                        if isValid(grid, row: r, col: c, num: n) {
                            grid[r][c] = n
                            if fillGrid(&grid) { return true }
                            grid[r][c] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }

    private func isValid(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Row check
        if grid[row].contains(num) { return false }
        // Column check
        if grid.map({ $0[col] }).contains(num) { return false }
        // Box check
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 {
                if grid[r][c] == num { return false }
            }
        }
        return true
    }

    // MARK: - Player Actions

    func select(row: Int, col: Int) {
        selectedCell = (row, col)
    }

    func placeNumber(_ number: Int) {
        guard let sel = selectedCell else { return }
        placeNumber(number, atRow: sel.row, col: sel.col)
    }

    func placeNumber(_ number: Int, atRow row: Int, col: Int) {
        guard !cells[row][col].isGiven else { return }
        cells[row][col].playerValue = number
    }

    func clearSelected() {
        guard let sel = selectedCell else { return }
        guard !cells[sel.row][sel.col].isGiven else { return }
        cells[sel.row][sel.col].playerValue = nil
    }

    func newGame() {
        selectedCell = nil
        generatePuzzle()
    }

    var isSolved: Bool {
        cells.allSatisfy { row in
            row.allSatisfy { cell in
                cell.isGiven || cell.playerValue == cell.solution
            }
        }
    }
}
