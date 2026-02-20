import SwiftUI

/// Fallback number pad for finger input (also works alongside Pencil).
struct NumberPadView: View {
    @ObservedObject var board: SudokuBoard

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...9, id: \.self) { num in
                Button {
                    board.placeNumber(num)
                } label: {
                    Text("\(num)")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            Button {
                board.clearSelected()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
}
