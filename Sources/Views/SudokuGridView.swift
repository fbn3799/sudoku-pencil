import SwiftUI

/// The main 9×9 Sudoku grid with a clean border and no overflow.
struct SudokuGridView: View {
    @ObservedObject var board: SudokuBoard
    let cellSize: CGFloat

    private let thinLine: CGFloat = 0.5
    private let thickLine: CGFloat = 2

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        let cell = board.cells[row][col]

                        SudokuCellView(
                            cell: cell,
                            cellSize: cellSize,
                            onTap: { board.select(row: row, col: col) }
                        )

                        // Internal vertical lines only
                        if col < 8 {
                            Rectangle()
                                .fill(col % 3 == 2 ? Color.primary : Color.primary.opacity(0.2))
                                .frame(width: col % 3 == 2 ? thickLine : thinLine)
                        }
                    }
                }

                // Internal horizontal lines only
                if row < 8 {
                    Rectangle()
                        .fill(row % 3 == 2 ? Color.primary : Color.primary.opacity(0.2))
                        .frame(height: row % 3 == 2 ? thickLine : thinLine)
                }
            }
        }
        .border(Color.primary, width: 2.5)
    }
}
