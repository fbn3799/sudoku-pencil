import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuCell
    let isSelected: Bool
    let cellSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor)

            // Number display
            if let value = cell.displayValue {
                Text("\(value)")
                    .font(.system(size: cellSize * 0.5, weight: cell.isGiven ? .bold : .regular, design: .rounded))
                    .foregroundColor(textColor)
                    .opacity(cell.isFlashingWrong ? 0.8 : 1.0)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .animation(.easeOut(duration: 0.5), value: cell.isFlashingWrong)
        .onTapGesture(perform: onTap)
    }

    private var backgroundColor: Color {
        if cell.isFlashingWrong {
            return Color.red.opacity(0.35)
        }
        if isSelected {
            return Color.blue.opacity(0.25)
        }
        // Alternate 3×3 box shading
        let boxShaded = ((cell.row / 3) + (cell.col / 3)) % 2 == 0
        return boxShaded ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }

    private var textColor: Color {
        if cell.isGiven { return .primary }
        if cell.isFlashingWrong { return .red }
        return .blue
    }
}
