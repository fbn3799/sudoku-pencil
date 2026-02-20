import PencilKit
import Vision
import UIKit

/// Recognizes handwritten digits from PencilKit strokes using Vision framework.
class DigitRecognizer {
    /// Attempt to recognize a single digit (1-9) from the given drawing.
    static func recognize(drawing: PKDrawing, completion: @escaping (Int?) -> Void) {
        let bounds = drawing.bounds
        guard !bounds.isEmpty else {
            completion(nil)
            return
        }

        // Render the drawing to an image with padding.
        let padding: CGFloat = 20
        let size = CGSize(
            width: max(bounds.width, bounds.height) + padding * 2,
            height: max(bounds.width, bounds.height) + padding * 2
        )

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))

            let offsetX = (size.width - bounds.width) / 2 - bounds.origin.x
            let offsetY = (size.height - bounds.height) / 2 - bounds.origin.y
            ctx.cgContext.translateBy(x: offsetX, y: offsetY)

            let drawingImage = drawing.image(from: drawing.bounds, scale: 2.0)
            drawingImage.draw(in: drawing.bounds)
        }

        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        // Use Vision text recognition.
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRecognizedTextObservation],
                  let topCandidate = results.first?.topCandidates(1).first else {
                completion(nil)
                return
            }

            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            // Extract single digit 1-9.
            if let digit = Int(text), (1...9).contains(digit) {
                completion(digit)
            } else {
                completion(nil)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        // Constrain to digits only.
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
