import SwiftUI

/// The main 9×9 Sudoku grid — no outer border, only internal lines.
struct SudokuGridView: View {
    @ObservedObject var board: SudokuBoard
    let cellSize: CGFloat

    private let thinLine: CGFloat = 0.5
    private let thickLine: CGFloat = 2.5

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

                        if col < 8 {
                            Rectangle()
                                .fill(Color.gray.opacity(col % 3 == 2 ? 1 : 0.3))
                                .frame(width: col % 3 == 2 ? thickLine : thinLine)
                        }
                    }
                }

                if row < 8 {
                    Rectangle()
                        .fill(Color.gray.opacity(row % 3 == 2 ? 1 : 0.3))
                        .frame(height: row % 3 == 2 ? thickLine : thinLine)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
