import SwiftUI
import PencilKit

/// Transparent PencilKit canvas that overlays the entire grid.
/// Strokes are drawn in-place; after a pause, the cell under the stroke is detected,
/// the digit is recognized, and placed into the board.
struct PencilInputOverlay: UIViewRepresentable {
    @ObservedObject var board: SudokuBoard
    let cellSize: CGFloat
    let gridOrigin: CGPoint  // top-left of the 9×9 cell area in overlay coords

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3.5)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.cellSize = cellSize
        context.coordinator.gridOrigin = gridOrigin
        context.coordinator.board = board
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(board: board, cellSize: cellSize, gridOrigin: gridOrigin)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var board: SudokuBoard
        var cellSize: CGFloat
        var gridOrigin: CGPoint
        private var recognitionTimer: Timer?

        init(board: SudokuBoard, cellSize: CGFloat, gridOrigin: CGPoint) {
            self.board = board
            self.cellSize = cellSize
            self.gridOrigin = gridOrigin
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            recognitionTimer?.invalidate()
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let drawing = canvasView.drawing
                guard !drawing.strokes.isEmpty else { return }

                // Find which cell the strokes center on.
                let bounds = drawing.bounds
                let centerX = bounds.midX - self.gridOrigin.x
                let centerY = bounds.midY - self.gridOrigin.y

                let col = Int(centerX / self.cellSize)
                let row = Int(centerY / self.cellSize)

                guard (0..<9).contains(row), (0..<9).contains(col) else {
                    self.fadeAndClear(canvasView)
                    return
                }

                // Don't overwrite given cells.
                guard !self.board.cells[row][col].isGiven else {
                    self.fadeAndClear(canvasView)
                    return
                }

                // Select the cell visually.
                DispatchQueue.main.async {
                    self.board.select(row: row, col: col)
                }

                // Recognize the digit.
                DigitRecognizer.recognize(drawing: drawing) { digit in
                    DispatchQueue.main.async {
                        if let digit = digit {
                            self.board.placeNumber(digit)
                        }
                        // Fade out strokes, then clear.
                        self.fadeAndClear(canvasView)
                    }
                }
            }
        }

        private func fadeAndClear(_ canvasView: PKCanvasView) {
            UIView.animate(withDuration: 0.35, animations: {
                canvasView.alpha = 0.0
            }, completion: { _ in
                canvasView.drawing = PKDrawing()
                canvasView.alpha = 1.0
            })
        }
    }
}
