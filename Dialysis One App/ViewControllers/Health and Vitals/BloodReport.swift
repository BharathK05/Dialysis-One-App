//
//  BloodReport.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import Foundation

struct BloodReport: Codable {
    let id: String
    var title: String
    var type: String
    var date: Date
    var filename: String?        // stored inside Documents
    var thumbnailData: Data?     // small jpg/png

    var attachmentURL: URL? {
        guard let fname = filename else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fname)
    }

    init(title: String, type: String, date: Date, filename: String? = nil, thumbnailData: Data? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.type = type
        self.date = date
        self.filename = filename
        self.thumbnailData = thumbnailData
    }
}

