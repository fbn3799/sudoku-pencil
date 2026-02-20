import SwiftUI
import PencilKit

/// Full-screen transparent overlay that captures Apple Pencil input on the selected cell.
struct PencilInputOverlay: View {
    @ObservedObject var board: SudokuBoard

    var body: some View {
        if board.selectedCell != nil,
           let sel = board.selectedCell,
           !board.cells[sel.row][sel.col].isGiven {
            CellCanvasView { digit in
                board.placeNumber(digit)
                // Auto-advance: deselect after placing
                // board.selectedCell = nil
            }
            .allowsHitTesting(true)
            .frame(width: 200, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 2)
            )
            .overlay(alignment: .top) {
                Text("Draw a digit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}
