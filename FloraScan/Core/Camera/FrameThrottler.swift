//
//  FrameThrottler.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import QuartzCore
import os

final class FrameThrottler: @unchecked Sendable {
    private let interval: TimeInterval
    private let lock = OSAllocatedUnfairLock(initialState: TimeInterval(0))

    init(framesPerSecond: Double) {
        self.interval = 1.0 / framesPerSecond
    }

    nonisolated func shouldFire(now: TimeInterval = CACurrentMediaTime()) -> Bool {
        lock.withLock { lastFireTime in
            if now - lastFireTime >= interval {
                lastFireTime = now
                return true
            }
            return false
        }
    }
}
