//
//  HealthKitManager.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    // MARK: - Types we read
    let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    ]

    private init() {}

    // MARK: - Request Permission
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        store.requestAuthorization(
            toShare: [],
            read: readTypes,
            completion: completion
        )
    }
    
    func startObservingForBackground() {
        observeWithObserverQuery(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) { value, date in
            NotificationEvaluator.shared.evaluate(heartRate: value, spo2: nil, timestamp: date)
        }
        observeWithObserverQuery(.oxygenSaturation, unit: HKUnit.percent()) { value, date in
            NotificationEvaluator.shared.evaluate(heartRate: nil, spo2: value, timestamp: date)
        }
    }

    private func observeWithObserverQuery(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, _ callback: @escaping (Double, Date) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, error in
            guard error == nil else {
                print("Observer error: \(error!.localizedDescription)")
                return
            }
            // When observer fires, run an anchored query to fetch new samples
            let anchored = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: 1) { _, samples, newAnchor, _, err in
                if let sample = samples?.last as? HKQuantitySample {
                    let val = sample.quantity.doubleValue(for: unit)
                    DispatchQueue.main.async { callback(val, sample.endDate) }
                }
            }
            self?.store.execute(anchored)
        }
        store.execute(query)
    }


    // MARK: - Read Most Recent Value
    func readMostRecentSample(ofType identifier: HKQuantityTypeIdentifier,
                              completion: @escaping (Double?, Date?, Error?) -> Void) {

        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil, nil)
            return
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, results, error in

            if let error = error {
                completion(nil, nil, error)
                return
            }

            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil, nil, nil)
                return
            }

            let unit: HKUnit = {
                switch identifier {
                case .heartRate: return HKUnit.count().unitDivided(by: .minute())
                case .oxygenSaturation: return .percent()
                default: return .count()
                }
            }()

            let value = sample.quantity.doubleValue(for: unit)
            completion(value, sample.endDate, nil)
        }

        store.execute(query)
    }

    // MARK: - Helper to process samples
    private func processSamples(_ samples: [HKSample]?, unit: HKUnit,
                                _ callback: @escaping (Double, Date) -> Void) {

        guard let sample = samples?.last as? HKQuantitySample else { return }
        let value = sample.quantity.doubleValue(for: unit)
        callback(value, sample.endDate)
    }
}

