//
//  File.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private init() {}

    // Request permission for heart rate + oxygen
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]

        store.requestAuthorization(toShare: [], read: types, completion: completion)
    }

    // Fetch most recent sample for given type
    func readMostRecentSample(ofType identifier: HKQuantityTypeIdentifier,
                              completion: @escaping (Double?, Date?, Error?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil, nil)
            return
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, error in
            if let err = error {
                completion(nil, nil, err)
                return
            }
            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil, nil, nil)
                return
            }

            let unit: HKUnit
            switch identifier {
            case .heartRate:
                unit = HKUnit.count().unitDivided(by: HKUnit.minute()) // bpm
            case .oxygenSaturation:
                unit = HKUnit.percent()
            default:
                unit = HKUnit.count()
            }

            let value = sample.quantity.doubleValue(for: unit)
            completion(value, sample.startDate, nil)
        }
        store.execute(q)
    }
}

