import SwiftUI

/// The main 9×9 Sudoku grid, drawn with thick box borders.
struct SudokuGridView: View {
    @ObservedObject var board: SudokuBoard
    let cellSize: CGFloat

    private let thinLine: CGFloat = 0.5
    private let thickLine: CGFloat = 2.5

    var body: some View {
        let gridSize = cellSize * 9 + thickLine * 4 + thinLine * 6

        ZStack {
            // Cell grid
            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { col in
                            let cell = board.cells[row][col]
                            let isSelected = board.selectedCell?.row == row && board.selectedCell?.col == col

                            SudokuCellView(
                                cell: cell,
                                isSelected: isSelected,
                                cellSize: cellSize
                            ) {
                                board.select(row: row, col: col)
                            }

                            // Vertical separators
                            if col < 8 {
                                Rectangle()
                                    .fill(Color.gray.opacity(col % 3 == 2 ? 1 : 0.3))
                                    .frame(width: col % 3 == 2 ? thickLine : thinLine)
                            }
                        }
                    }

                    // Horizontal separators
                    if row < 8 {
                        Rectangle()
                            .fill(Color.gray.opacity(row % 3 == 2 ? 1 : 0.3))
                            .frame(height: row % 3 == 2 ? thickLine : thinLine)
                    }
                }
            }

            // Outer border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary, lineWidth: thickLine)
                .frame(width: gridSize, height: gridSize)
        }
    }
}
