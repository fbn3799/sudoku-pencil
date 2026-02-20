import PencilKit
import Vision
import UIKit

/// Recognizes handwritten digits from PencilKit strokes.
/// Uses Vision at high resolution + stroke geometry heuristics as fallback.
class DigitRecognizer {

    private static let charToDigit: [String: Int] = [
        "1": 1, "l": 1, "I": 1, "|": 1, "i": 1, "!": 1,
        "2": 2, "Z": 2, "z": 2,
        "3": 3,
        "4": 4, "A": 4,
        "5": 5, "S": 5, "s": 5,
        "6": 6, "G": 6, "b": 6,
        "7": 7, "T": 7, "/": 7,
        "8": 8, "B": 8,
        "9": 9, "g": 9, "q": 9, "p": 9,
        "0": 0, "O": 0, "o": 0, "D": 0,
    ]

    static func recognize(drawing: PKDrawing, completion: @escaping (Int?) -> Void) {
        let bounds = drawing.bounds
        guard !bounds.isEmpty else { completion(nil); return }

        // Render large (400px) with thick strokes for best OCR.
        let targetSize: CGFloat = 400
        let padding: CGFloat = 60
        let contentSide = max(bounds.width, bounds.height)
        guard contentSide > 0 else { completion(nil); return }
        let scale = (targetSize - padding * 2) / contentSide

        let renderSize = CGSize(width: targetSize, height: targetSize)
        let renderer = UIGraphicsImageRenderer(size: renderSize)

        let finalImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))

            let cgCtx = ctx.cgContext
            cgCtx.translateBy(x: targetSize / 2, y: targetSize / 2)
            cgCtx.scaleBy(x: scale, y: scale)
            cgCtx.translateBy(x: -bounds.midX, y: -bounds.midY)

            // Draw strokes as thick black lines manually for maximum contrast.
            cgCtx.setStrokeColor(UIColor.black.cgColor)
            cgCtx.setLineCap(.round)
            cgCtx.setLineJoin(.round)
            cgCtx.setLineWidth(8.0 / scale)  // ~8px at output scale

            for stroke in drawing.strokes {
                let path = stroke.path
                guard path.count > 0 else { continue }
                cgCtx.beginPath()
                cgCtx.move(to: path[0].location)
                for i in 1..<path.count {
                    cgCtx.addLine(to: path[i].location)
                }
                cgCtx.strokePath()
            }
        }

        guard let cgImage = finalImage.cgImage else { completion(nil); return }

        // Run Vision OCR.
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
            // Try Vision results first.
            var bestDigit: Int? = nil
            var bestConf: Float = 0

            for (text, conf) in allCandidates {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if let d = Int(cleaned), (1...9).contains(d), conf > bestConf {
                    bestDigit = d; bestConf = conf
                }
                if cleaned.count == 1, let d = charToDigit[cleaned], d >= 1, d <= 9 {
                    let adjusted = conf * 0.9
                    if adjusted > bestConf { bestDigit = d; bestConf = adjusted }
                }
            }

            // If Vision got something with reasonable confidence, use it.
            if bestDigit != nil && bestConf > 0.2 {
                completion(bestDigit)
                return
            }

            // Fallback: stroke geometry heuristic.
            let heuristic = strokeHeuristic(drawing: drawing)
            completion(heuristic)
        }
    }

    /// Simple stroke-count + shape heuristic for digits 1-9.
    private static func strokeHeuristic(drawing: PKDrawing) -> Int? {
        let strokes = drawing.strokes
        guard !strokes.isEmpty else { return nil }

        let bounds = drawing.bounds
        let aspect = bounds.width / max(bounds.height, 1)

        // Single stroke digits
        if strokes.count == 1 {
            let path = strokes[0].path
            guard path.count > 1 else { return 1 }

            // Very narrow → likely 1
            if aspect < 0.3 { return 1 }

            // Check if the stroke is a closed loop (0, 6, 8, 9)
            let start = path[0].location
            let end = path[path.count - 1].location
            let dist = hypot(end.x - start.x, end.y - start.y)
            let pathLength = totalLength(path)
            let closedness = dist / max(pathLength, 1)

            if closedness < 0.15 {
                // Closed loop — could be 0, 6, 8, 9
                // Check if the loop crosses itself (8)
                if aspect > 0.4 && aspect < 0.8 {
                    return 8
                }
                return 0
            }
        }

        // 2 strokes → could be many things
        // 3+ strokes → could be 4, etc.

        return nil  // Can't determine
    }

    private static func totalLength(_ path: PKStrokePath) -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<path.count {
            let dx = path[i].location.x - path[i-1].location.x
            let dy = path[i].location.y - path[i-1].location.y
            length += hypot(dx, dy)
        }
        return length
    }
}
