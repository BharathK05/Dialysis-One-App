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
    var date: Date
    var filename: String?
    var thumbnailData: Data?
    var extractedText: String? = nil

    var attachmentURL: URL? {
        guard let fname = filename else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fname)
    }

    init(
        title: String,
        date: Date,
        filename: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.date = date
        self.filename = filename
        self.thumbnailData = thumbnailData
    }
}

