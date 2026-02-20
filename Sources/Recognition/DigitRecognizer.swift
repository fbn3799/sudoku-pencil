import PencilKit
import Vision
import UIKit

/// Recognizes handwritten digits from PencilKit strokes using Vision framework.
class DigitRecognizer {

    // Common OCR misreads → digit mapping.
    private static let charToDigit: [String: Int] = [
        "1": 1, "l": 1, "I": 1, "|": 1, "i": 1,
        "2": 2, "Z": 2, "z": 2,
        "3": 3,
        "4": 4, "A": 4,
        "5": 5, "S": 5, "s": 5,
        "6": 6, "G": 6, "b": 6,
        "7": 7, "T": 7,
        "8": 8, "B": 8,
        "9": 9, "g": 9, "q": 9,
    ]

    /// Attempt to recognize a single digit (1-9) from the given drawing.
    static func recognize(drawing: PKDrawing, completion: @escaping (Int?) -> Void) {
        let bounds = drawing.bounds
        guard !bounds.isEmpty else {
            completion(nil)
            return
        }

        // Render large and centered for best recognition.
        let targetSize: CGFloat = 300
        let padding: CGFloat = 40
        let contentSide = max(bounds.width, bounds.height)
        let scale = (targetSize - padding * 2) / max(contentSide, 1)

        let renderSize = CGSize(width: targetSize, height: targetSize)

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let finalImage = renderer.image { ctx in
            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))

            // Center and scale the drawing
            let cgCtx = ctx.cgContext
            cgCtx.translateBy(x: targetSize / 2, y: targetSize / 2)
            cgCtx.scaleBy(x: scale, y: scale)
            cgCtx.translateBy(x: -bounds.midX, y: -bounds.midY)

            // Render strokes in light mode for dark-on-white
            let tc = UITraitCollection(userInterfaceStyle: .light)
            tc.performAsCurrent {
                let img = drawing.image(from: bounds, scale: 4.0)
                img.draw(in: bounds)
            }
        }

        guard let cgImage = finalImage.cgImage else {
            completion(nil)
            return
        }

        // Run both accurate and fast recognition, take the best digit match.
        let group = DispatchGroup()
        var allCandidates: [(String, Float)] = []
        let lock = NSLock()

        for level in [VNRequestTextRecognitionLevel.accurate, .fast] {
            group.enter()
            let request = VNRecognizeTextRequest { request, error in
                defer { group.leave() }
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else { return }

                lock.lock()
                for obs in observations {
                    for candidate in obs.topCandidates(10) {
                        allCandidates.append((candidate.string, candidate.confidence))
                    }
                }
                lock.unlock()
            }
            request.recognitionLevel = level
            request.usesLanguageCorrection = false
            request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }

        group.notify(queue: .main) {
            // Find the best digit from all candidates.
            var bestDigit: Int? = nil
            var bestConf: Float = 0

            for (text, conf) in allCandidates {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // Direct digit match
                if let d = Int(cleaned), (1...9).contains(d), conf > bestConf {
                    bestDigit = d
                    bestConf = conf
                }
                // Character-level fallback for single chars
                if cleaned.count == 1, let d = charToDigit[cleaned], conf * 0.9 > bestConf {
                    bestDigit = d
                    bestConf = conf * 0.9
                }
            }

            completion(bestDigit)
        }
    }
}
