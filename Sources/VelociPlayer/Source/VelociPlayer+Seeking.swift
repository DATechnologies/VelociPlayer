//
//  VelociPlayer+Seeking.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 2/9/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    /// Request that the player seek to a specified percentage.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter percent: The percentage of playback to which to seek.
    public func seek(toPercent percent: Double) {
        Task.detached {
            await self.seek(toPercent: percent)
        }
    }
    
    /// Request that the player seek to a specified percentage, and to notify you when the seek is complete.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter percent: The percentage of playback to which to seek.
    /// - Returns: A boolean indicating whether the seek operation completed.
    @discardableResult
    public func seek(toPercent percent: Double) async -> Bool {
        let seconds = self.duration.seconds * percent
        return await self.seek(to: seconds)
    }
    
    /// Request that the player seek to a specified time interval.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter seconds: The time interval to which to seek.
    public func seek(to seconds: TimeInterval) {
        Task.detached {
            await self.seek(to: seconds)
        }
    }
    
    /// Request that the player seek to a specified time interval, and to notify you when the seek is complete.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter seconds: The time interval to which to seek.
    /// - Returns: A boolean indicating whether the seek operation completed.
    @discardableResult
    public func seek(to seconds: TimeInterval) async -> Bool {
        return await self.seek(to: VPTime(seconds: seconds, preferredTimescale: 1))
    }
    
    /// Request that the player seek to a specified time interval.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter time: The time to which to seek.
    override public func seek(to time: VPTime) {
        Task.detached {
            await self.seek(to: time)
        }
    }
    
    /// Request that the player seek to a specified time, and to notify you when the seek is complete.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter time: The time to which to seek.
    /// - Returns: A boolean indicating whether the seek operation completed.
    @discardableResult
    override public func seek(to time: VPTime) async -> Bool {
        self.beginPlayerObservationIfNeeded()
        let completed = await super.seek(to: time)
        await updateNowPlayingForSeeking()
        return completed
    }
    
    /// Requests that the player seek to a specified time with the amount of accuracy specified by the time tolerance values.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameters:
    ///   - time: The time to which to seek.
    ///   - toleranceBefore: The tolerance allowed before `time`.
    ///   - toleranceAfter: The tolerance allowed after `time`.
    override public func seek(
        to time: VPTime,
        toleranceBefore: VPTime,
        toleranceAfter: VPTime
    ) {
        Task.detached {
            await super.seek(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter
            )
        }
    }
    
    /// Requests that the player seek to a specified time with the amount of accuracy specified by the time tolerance values,
    /// and to notify you when the seek is complete.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameters:
    ///   - time: The time to which to seek.
    ///   - toleranceBefore: The tolerance allowed before `time`.
    ///   - toleranceAfter: The tolerance allowed after `time`.
    /// - Returns: A boolean indicating whether the seek operation completed.
    @discardableResult
    override public func seek(
        to time: VPTime,
        toleranceBefore: VPTime,
        toleranceAfter: VPTime
    ) async -> Bool {
        let completed = await super.seek(
            to: time,
            toleranceBefore: toleranceBefore,
            toleranceAfter: toleranceAfter
        )
        await updateNowPlayingForSeeking()
        return completed
    }
    
    /// Requests that the player seek to the specified date.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter date: The date to which to seek.
    override public func seek(to date: Date) {
        Task.detached {
            await self.seek(to: date)
        }
    }
    
    /// Requests that the player seek to the specified date, and to notify you when the seek is complete.
    ///
    /// For more information, see documentation on AVPlayer.
    /// - Parameter date: The date to which to seek.
    /// - Returns: A boolean indicating whether the seek operation completed.
    @discardableResult
    override public func seek(to date: Date) async -> Bool {
        let completed = await super.seek(to: date)
        await updateNowPlayingForSeeking()
        return completed
    }
}
