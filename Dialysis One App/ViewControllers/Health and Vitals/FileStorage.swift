//
//  FileStorage.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import Foundation
import UIKit
import PDFKit

final class FileStorage {
    static let shared = FileStorage()
    private let reportsKey = "SavedBloodReports_v1"

    private init(){}

    // MARK: - Reports persistence
    func saveReports(_ reports: [BloodReport]) {
        do {
            let data = try JSONEncoder().encode(reports)
            UserDefaults.standard.set(data, forKey: reportsKey)
        } catch {
            print("Failed to save reports: \(error)")
        }
    }

    func loadReports() -> [BloodReport] {
        guard let data = UserDefaults.standard.data(forKey: reportsKey) else { return [] }
        do {
            let arr = try JSONDecoder().decode([BloodReport].self, from: data)
            return arr
        } catch {
            print("Failed to decode reports: \(error)")
            return []
        }
    }

    // Save a PDF file into Documents and return filename
    func copyFileToDocuments(sourceURL: URL) throws -> String {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(sourceURL.lastPathComponent)

        // if exists, add suffix
        var target = dest
        var counter = 1
        while fm.fileExists(atPath: target.path) {
            let name = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            let newName = "\(name)-\(counter).\(ext)"
            target = docs.appendingPathComponent(newName)
            counter += 1
        }

        try fm.copyItem(at: sourceURL, to: target)
        return target.lastPathComponent
    }

    // Generate PDF thumbnail
    func generatePDFThumbnail(url: URL, size: CGSize) -> UIImage? {
        guard let doc = PDFDocument(url: url), let page = doc.page(at: 0) else { return nil }
        let pdfRect = page.bounds(for: .mediaBox)
        let scale = min(size.width/pdfRect.width, size.height/pdfRect.height)
        let targetSize = CGSize(width: pdfRect.width*scale, height: pdfRect.height*scale)

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        // white background
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(origin: .zero, size: targetSize))

        let drawRect = CGRect(origin: .zero, size: targetSize)
        page.draw(with: .mediaBox, to: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Save a PDF into Documents folder
    func saveReportFile(url: URL, name: String) {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(name)

        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            print("📄 Saved PDF file at: \(dest)")
        } catch {
            print("❌ Failed to save report file: \(error)")
        }
    }

    // MARK: - Save a single report record
    func saveReport(_ report: BloodReport) {
        var existing = loadReports()
        existing.append(report)
        saveReports(existing)
    }

}

