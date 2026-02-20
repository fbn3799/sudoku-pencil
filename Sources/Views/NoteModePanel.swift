import SwiftUI

/// Floating note mode toolbar with color picker, eraser, erase-all, and close.
struct NoteModePanel: View {
    @ObservedObject var noteMode: NoteModeState
    let onEraseAll: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Color swatches
            ForEach(noteMode.availableColors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: noteMode.selectedColor == color && !noteMode.isErasing ? 2.5 : 0)
                            .padding(-3)
                    )
                    .onTapGesture { noteMode.selectColor(color) }
            }

            Divider().frame(height: 28)

            // Eraser
            Button {
                noteMode.toggleEraser()
            } label: {
                Image(systemName: noteMode.isErasing ? "eraser.fill" : "eraser")
                    .font(.title3)
                    .foregroundColor(noteMode.isErasing ? .blue : .secondary)
            }

            // Erase all
            Button {
                onEraseAll()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }

            Divider().frame(height: 28)

            // Close note mode
            Button {
                noteMode.deactivate()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
}
