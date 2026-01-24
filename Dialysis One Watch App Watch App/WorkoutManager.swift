//
//  WorkoutManager.swift
//  Dialysis One Watch App
//
//  Created by user@22 on 15/12/25.
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
        config.activityType = .other
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
            builder?.beginCollection(withStart: startDate) { _, _ in }

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
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {}
}