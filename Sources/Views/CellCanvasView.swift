import SwiftUI
import PencilKit

/// A PencilKit canvas overlay for a single Sudoku cell.
/// The user draws a digit with Apple Pencil; on stroke end it's recognized and placed.
struct CellCanvasView: UIViewRepresentable {
    let onRecognized: (Int) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly  // Apple Pencil only
        canvas.tool = PKInkingTool(.pen, color: .label, width: 4)
        canvas.delegate = context.coordinator
        canvas.overrideUserInterfaceStyle = .unspecified
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecognized: onRecognized)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onRecognized: (Int) -> Void
        private var recognitionTimer: Timer?

        init(onRecognized: @escaping (Int) -> Void) {
            self.onRecognized = onRecognized
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Debounce: wait 0.6s after last stroke before recognizing.
            recognitionTimer?.invalidate()
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
                let drawing = canvasView.drawing
                guard !drawing.strokes.isEmpty else { return }

                DigitRecognizer.recognize(drawing: drawing) { digit in
                    DispatchQueue.main.async {
                        if let digit = digit {
                            self?.onRecognized(digit)
                        }
                        // Clear the canvas after recognition attempt.
                        canvasView.drawing = PKDrawing()
                    }
                }
            }
        }
    }
}
