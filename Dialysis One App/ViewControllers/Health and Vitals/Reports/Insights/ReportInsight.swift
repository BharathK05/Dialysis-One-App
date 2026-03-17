//
//  ReportInsight.swift
//  Dialysis One App
//
//  Created by user@22 on 04/02/26.
//


import Foundation

enum InsightTone: String, Codable {
    case neutral
    case reassuring
    case attention
}

enum InsightSection: String, Codable {
    case summary
    case vital
}

struct ReportInsight: Codable, Identifiable {
    let id: String
    let section: InsightSection   // 👈 NEW
    let title: String
    let message: String
    let tone: InsightTone
    let reportDate: Date

    init(
        section: InsightSection,
        title: String,
        message: String,
        tone: InsightTone,
        reportDate: Date
    ) {
        self.id = UUID().uuidString
        self.section = section
        self.title = title
        self.message = message
        self.tone = tone
        self.reportDate = reportDate
    }
}

