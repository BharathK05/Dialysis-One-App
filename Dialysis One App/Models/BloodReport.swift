//
//  BloodReport.swift
//  Dialysis One App
//
//  Created by user@22 on 09/11/25.
//

import Foundation

struct BloodReport {
    let id: String
    let title: String
    let type: String
    let date: Date
    let attachmentURL: URL?
    let thumbnailImage: Data? // Store PDF thumbnail as Data
    
    init(title: String, type: String, date: Date, attachmentURL: URL? = nil, thumbnailImage: Data? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.type = type
        self.date = date
        self.attachmentURL = attachmentURL
        self.thumbnailImage = thumbnailImage
    }
}
