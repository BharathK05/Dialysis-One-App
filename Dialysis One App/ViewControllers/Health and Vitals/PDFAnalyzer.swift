import PDFKit

final class PDFAnalyzer {

    static func extractText(from url: URL) -> String {
        guard let doc = PDFDocument(url: url) else { return "" }

        return (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
    }
}
