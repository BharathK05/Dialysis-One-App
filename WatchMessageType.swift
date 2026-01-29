//
//  WatchMessageType.swift
//  Dialysis One App
//
//  Created by user@22 on 17/12/25.
//


import Foundation

enum WatchMessageType: String {
    case summary        = "summary"
    case addWater       = "add_water"
    case addMedication  = "add_medication"   
    case vitals         = "vitals"
    case alert          = "alert"
    case auth           = "auth"
}

