//
//  PDFHelper.swift
//  Dialysis One App
//
//  Created by user@22 on 09/11/25.
//


import UIKit
import PDFKit

class PDFHelper {
    
    /// Generate thumbnail from first page of PDF
    static func generateThumbnail(from url: URL, size: CGSize = CGSize(width: 120, height: 120)) -> UIImage? {
        guard let document = PDFDocument(url: url) else {
            print("Failed to load PDF document")
            return nil
        }
        
        guard let page = document.page(at: 0) else {
            print("Failed to get first page of PDF")
            return nil
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let thumbnail = renderer.image { context in
            // Fill background with white
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Calculate scale to fit
            let scaleX = size.width / pageRect.width
            let scaleY = size.height / pageRect.height
            let scale = min(scaleX, scaleY)
            
            // Center the page
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let x = (size.width - scaledWidth) / 2
            let y = (size.height - scaledHeight) / 2
            
            context.cgContext.translateBy(x: x, y: y)
            context.cgContext.scaleBy(x: scale, y: scale)
            
            // Draw PDF page
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        return thumbnail
    }
    
    /// Convert UIImage to Data for storage
    static func imageToData(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 0.7)
    }
    
    /// Convert Data back to UIImage
    static func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}
