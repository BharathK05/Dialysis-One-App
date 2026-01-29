//
//  WorkoutManager.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//

import Foundation
import HealthKit

final class WorkoutManager: NSObject {

    static let shared = WorkoutManager()

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var isRunning = false

    func start() {
        guard !isRunning else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .mindAndBody
        config.locationType = .unknown

        do {
            session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: config
            )

            builder = session?.associatedWorkoutBuilder()

            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )

            session?.delegate = self
            builder?.delegate = self

            let startDate = Date()
            session?.startActivity(with: startDate)

            builder?.beginCollection(withStart: startDate) { success, error in
                print(success
                      ? "✅ Workout collection started"
                      : "❌ Failed to begin collection")
            }

            isRunning = true
        } catch {
            print("❌ Workout start failed:", error)
        }
    }



    func stopIfNeeded() {
        guard isRunning else { return }

        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            self.builder?.finishWorkout { _, _ in }
        }

        cleanup()
    }

    private func cleanup() {
        isRunning = false
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                         didChangeTo toState: HKWorkoutSessionState,
                         from fromState: HKWorkoutSessionState,
                         date: Date) {
        if toState == .ended {
            cleanup()
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                         didFailWithError error: Error) {
        cleanup()
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("📡 Collected types:", collectedTypes.map { $0.identifier })

        for type in collectedTypes {
            guard let qType = type as? HKQuantityType else { continue }

            if let stats = workoutBuilder.statistics(for: qType),
               let quantity = stats.mostRecentQuantity() {

                DispatchQueue.main.async {
                    if qType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                        let bpm = quantity.doubleValue(
                            for: HKUnit.count().unitDivided(by: .minute())
                        )
                        HealthKitManager.shared.updateHeartRate(bpm)
                    }

                    if qType.identifier == HKQuantityTypeIdentifier.oxygenSaturation.rawValue {
                        let sp = quantity.doubleValue(for: .percent()) * 100
                        HealthKitManager.shared.updateSpO2(sp)
                    }
                }
            }
        }
    }
}
