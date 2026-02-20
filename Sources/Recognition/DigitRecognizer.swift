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

        // Render with padding into a square image using PencilKit's own renderer.
        let padding: CGFloat = 30
        let side = max(bounds.width, bounds.height) + padding * 2
        let renderRect = CGRect(
            x: bounds.midX - side / 2,
            y: bounds.midY - side / 2,
            width: side,
            height: side
        )

        // PencilKit renders strokes as dark on transparent; we need dark on white.
        let traitCollection = UITraitCollection(userInterfaceStyle: .light)
        let strokeImage = drawing.image(from: renderRect, scale: 2.0, userInterfaceStyle: traitCollection)

        // Composite onto white background.
        let renderer = UIGraphicsImageRenderer(size: strokeImage.size)
        let finalImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: strokeImage.size))
            strokeImage.draw(at: .zero)
        }

        guard let cgImage = finalImage.cgImage else {
            completion(nil)
            return
        }

        // Use Vision text recognition.
        let request = VNRecognizeTextRequest { request, error in
            let result: Int? = {
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    return nil
                }

                // Check all candidates for a single digit.
                for obs in observations {
                    for candidate in obs.topCandidates(5) {
                        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let digit = Int(text), (1...9).contains(digit) {
                            return digit
                        }
                    }
                }
                return nil
            }()

            DispatchQueue.main.async {
                completion(result)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
