import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuCell
    let cellSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            if let value = cell.displayValue {
                Text("\(value)")
                    .font(.system(size: cellSize * 0.5, weight: cell.isGiven ? .bold : .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .animation(.easeInOut(duration: 0.3), value: cell.highlight)
        .onTapGesture(perform: onTap)
    }

    private var backgroundColor: Color {
        switch cell.highlight {
        case .correct:
            return Color.green.opacity(0.3)
        case .wrong:
            return Color.red.opacity(0.35)
        case .active:
            return Color.gray.opacity(0.2)
        case .none:
            let boxShaded = ((cell.row / 3) + (cell.col / 3)) % 2 == 0
            return boxShaded ? Color(.systemBackground) : Color(.secondarySystemBackground)
        }
    }
}
