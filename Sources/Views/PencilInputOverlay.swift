import SwiftUI
import PencilKit

/// Transparent PencilKit canvas overlaying the entire grid.
/// In normal mode: recognizes digits. In note mode: free drawing with selected color/eraser.
struct PencilInputOverlay: UIViewRepresentable {
    @ObservedObject var board: SudokuBoard
    @ObservedObject var noteMode: NoteModeState
    let cellSize: CGFloat
    let gridOrigin: CGPoint

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = PKInkingTool(.pen, color: .label, width: 3.5)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.cellSize = cellSize
        context.coordinator.gridOrigin = gridOrigin
        context.coordinator.board = board
        context.coordinator.noteMode = noteMode

        if noteMode.isActive {
            if noteMode.isErasing {
                uiView.tool = PKEraserTool(.vector)
            } else {
                let uiColor = UIColor(noteMode.selectedColor)
                uiView.tool = PKInkingTool(.pen, color: uiColor, width: 2.5)
            }
            // In note mode, keep strokes visible (don't auto-clear).
            context.coordinator.isNoteMode = true
        } else {
            // Normal mode: primary color, auto-recognize.
            uiView.tool = PKInkingTool(.pen, color: .label, width: 3.5)
            context.coordinator.isNoteMode = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(board: board, noteMode: noteMode, cellSize: cellSize, gridOrigin: gridOrigin)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var board: SudokuBoard
        var noteMode: NoteModeState
        var cellSize: CGFloat
        var gridOrigin: CGPoint
        var isNoteMode: Bool = false
        private var recognitionTimer: Timer?
        /// Strokes that belong to note mode (preserved across clears).
        var noteDrawing: PKDrawing = PKDrawing()

        init(board: SudokuBoard, noteMode: NoteModeState, cellSize: CGFloat, gridOrigin: CGPoint) {
            self.board = board
            self.noteMode = noteMode
            self.cellSize = cellSize
            self.gridOrigin = gridOrigin
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // In note mode, don't recognize — just let the user draw freely.
            guard !isNoteMode else { return }

            recognitionTimer?.invalidate()
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let drawing = canvasView.drawing
                guard !drawing.strokes.isEmpty else { return }

                let bounds = drawing.bounds
                let centerX = bounds.midX - self.gridOrigin.x
                let centerY = bounds.midY - self.gridOrigin.y

                let col = Int(centerX / self.cellSize)
                let row = Int(centerY / self.cellSize)

                guard (0..<9).contains(row), (0..<9).contains(col) else {
                    self.fadeAndClear(canvasView)
                    return
                }

                guard !self.board.cells[row][col].isGiven else {
                    self.fadeAndClear(canvasView)
                    return
                }

                // Highlight cell grey while recognizing.
                DispatchQueue.main.async {
                    self.board.select(row: row, col: col)
                }

                DigitRecognizer.recognize(drawing: drawing) { digit in
                    if let digit = digit {
                        self.board.placeNumber(digit, atRow: row, col: col)
                    } else {
                        // Unrecognized: fade the grey highlight.
                        self.board.fadeHighlight(row: row, col: col)
                    }
                    self.fadeAndClear(canvasView)
                }
            }
        }

        private func fadeAndClear(_ canvasView: PKCanvasView) {
            UIView.animate(withDuration: 0.3, animations: {
                canvasView.alpha = 0.0
            }, completion: { _ in
                canvasView.drawing = PKDrawing()
                canvasView.alpha = 1.0
            })
        }

        func eraseAll(_ canvasView: PKCanvasView) {
            canvasView.drawing = PKDrawing()
        }
    }
}
