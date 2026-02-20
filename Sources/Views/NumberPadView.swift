import SwiftUI

/// Compact number pad for finger input as alternative to Pencil.
struct NumberPadView: View {
    @ObservedObject var board: SudokuBoard
    var axis: Axis = .horizontal

    var body: some View {
        let content = Group {
            ForEach(1...9, id: \.self) { num in
                Button {
                    board.placeNumber(num)
                } label: {
                    Text("\(num)")
                        .font(.title3.weight(.medium).monospacedDigit())
                        .frame(width: 40, height: 40)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Button {
                board.clearSelected()
            } label: {
                Image(systemName: "delete.backward")
                    .font(.body.weight(.medium))
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }

        if axis == .horizontal {
            HStack(spacing: 8) { content }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 8)], spacing: 8) { content }
                .frame(maxWidth: 140)
        }
    }
}
