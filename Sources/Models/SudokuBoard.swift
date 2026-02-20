import Foundation
import Combine

/// Cell highlight state for animations.
enum CellHighlight: Equatable {
    case none
    case active       // grey: drawing in progress / just tapped
    case correct      // green flash
    case wrong        // red flash
}

/// Represents a single cell on the Sudoku board.
struct SudokuCell: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let col: Int
    let solution: Int
    let isGiven: Bool
    var playerValue: Int?
    var highlight: CellHighlight = .none

    var isEmpty: Bool { !isGiven && playerValue == nil }
    var isCorrect: Bool { playerValue == solution }
    var isFilled: Bool { isGiven || playerValue != nil }
    var displayValue: Int? { isGiven ? solution : playerValue }
}

/// Full 9×9 Sudoku board with puzzle generation.
class SudokuBoard: ObservableObject {
    @Published var cells: [[SudokuCell]]
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var difficulty: Difficulty

    enum Difficulty: String, CaseIterable, Codable {
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

    func generatePuzzle() {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)

        var removed = Set<Int>()
        while removed.count < difficulty.cellsToRemove {
            removed.insert(Int.random(in: 0..<81))
        }

        var newCells: [[SudokuCell]] = []
        for r in 0..<9 {
            var row: [SudokuCell] = []
            for c in 0..<9 {
                let idx = r * 9 + c
                let isGiven = !removed.contains(idx)
                row.append(SudokuCell(row: r, col: c, solution: grid[r][c], isGiven: isGiven))
            }
            newCells.append(row)
        }
        cells = newCells
        selectedCell = nil
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
        if grid[row].contains(num) { return false }
        if grid.map({ $0[col] }).contains(num) { return false }
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
        // Clear previous highlight.
        if let prev = selectedCell {
            cells[prev.row][prev.col].highlight = .none
        }
        selectedCell = (row, col)
        cells[row][col].highlight = .active
    }

    func placeNumber(_ number: Int) {
        guard let sel = selectedCell else { return }
        placeNumber(number, atRow: sel.row, col: sel.col)
    }

    func placeNumber(_ number: Int, atRow row: Int, col: Int) {
        guard !cells[row][col].isGiven else { return }

        if number == cells[row][col].solution {
            // Correct: flash green briefly, then place.
            cells[row][col].highlight = .correct
            cells[row][col].playerValue = number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.cells[row][col].highlight = .none
            }
        } else {
            // Wrong: flash red, then fade out.
            cells[row][col].highlight = .wrong
            cells[row][col].playerValue = number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.cells[row][col].playerValue = nil
                self?.cells[row][col].highlight = .none
            }
        }
    }

    /// Mark cell as active (drawing in progress).
    func highlightCell(row: Int, col: Int) {
        cells[row][col].highlight = .active
    }

    /// Clear highlight without placing a number (unrecognized stroke).
    func fadeHighlight(row: Int, col: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            if self?.cells[row][col].highlight == .active {
                self?.cells[row][col].highlight = .none
            }
        }
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

    // MARK: - Save/Restore

    func toSavedGame() -> SavedGame {
        SavedGame(
            id: UUID(),
            date: Date(),
            difficulty: difficulty.rawValue,
            solutions: cells.flatMap { $0.map { $0.solution } },
            givens: cells.flatMap { $0.map { $0.isGiven } },
            playerValues: cells.flatMap { $0.map { $0.playerValue } }
        )
    }

    func restore(from saved: SavedGame) {
        guard let diff = Difficulty(rawValue: saved.difficulty) else { return }
        self.difficulty = diff
        var newCells: [[SudokuCell]] = []
        for r in 0..<9 {
            var row: [SudokuCell] = []
            for c in 0..<9 {
                let idx = r * 9 + c
                var cell = SudokuCell(
                    row: r, col: c,
                    solution: saved.solutions[idx],
                    isGiven: saved.givens[idx]
                )
                cell.playerValue = saved.playerValues[idx]
                row.append(cell)
            }
            newCells.append(row)
        }
        cells = newCells
        selectedCell = nil
    }
}
