//
//  PDFTextPipeline.swift
//  Dialysis One App
//
//  Created by user@22 on 04/02/26.
//


import PDFKit
import Vision
import UIKit

final class PDFTextPipeline {

    static func extractText(from url: URL, completion: @escaping (String?) -> Void) {

        // 1️⃣ Try direct text extraction first
        if let text = extractSelectableText(from: url),
           text.trimmingCharacters(in: .whitespacesAndNewlines).count > 30 {
            completion(text)
            return
        }

        // 2️⃣ Fallback to OCR
        extractTextUsingOCR(from: url, completion: completion)
    }

    // MARK: - Text-based PDF
    private static func extractSelectableText(from url: URL) -> String? {
        guard let doc = PDFDocument(url: url) else { return nil }

        return (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
    }

    // MARK: - OCR (Scanned PDF)
    private static func extractTextUsingOCR(
        from url: URL,
        completion: @escaping (String?) -> Void
    ) {
        guard let doc = PDFDocument(url: url) else {
            completion(nil)
            return
        }

        var fullText = ""
        let queue = DispatchQueue(label: "ocr.queue", qos: .userInitiated)
        let group = DispatchGroup()

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }

            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)

            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            group.enter()
            queue.async {
                recognizeText(from: image) { text in
                    if let text = text {
                        fullText += "\n" + text
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(fullText.isEmpty ? nil : fullText)
        }
    }

    private static func recognizeText(
        from image: UIImage,
        completion: @escaping (String?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            let text = request.results?
                .compactMap { $0 as? VNRecognizedTextObservation }
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            completion(text)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
}
