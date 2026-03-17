//
//  ReportMetric.swift
//  Dialysis One App
//
//  Created by user@22 on 31/01/26.
//


import Foundation

struct ReportMetric: Codable {
    let name: String
    let value: Double
    let unit: String
    let referenceRange: String?
}
