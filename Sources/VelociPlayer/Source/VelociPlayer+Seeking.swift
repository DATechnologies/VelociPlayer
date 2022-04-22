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
    // MARK: - Seeking
    public func seek(toPercent percent: Double) {
        Task.detached {
            await seek(toPercent: percent)
        }
    }
    
    @discardableResult
    public func seek(toPercent percent: Double) async -> Bool {
        let seconds = self.duration.seconds * percent
        return await self.seek(to: seconds)
    }
    
    public func seek(to seconds: TimeInterval) {
        Task.detached {
            await seek(to: seconds)
        }
    }
    
    @discardableResult
    public func seek(to seconds: TimeInterval) async -> Bool {
        return await self.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
    }
    
    override public func seek(to time: CMTime) {
        Task.detached {
            await self.seek(to: time)
        }
    }
    
    @discardableResult
    override public func seek(to time: CMTime) async -> Bool {
        let completed = await super.seek(to: time)
        await updateNowPlayingForSeeking()
        return completed
    }
    
    override public func seek(
        to time: CMTime,
        toleranceBefore: CMTime,
        toleranceAfter: CMTime
    ) {
        Task.detached {
            await self.seek(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter
            )
        }
    }
    
    @discardableResult
    override public func seek(
        to time: CMTime,
        toleranceBefore: CMTime,
        toleranceAfter: CMTime
    ) async -> Bool {
        let completed = await super.seek(
            to: time,
            toleranceBefore: toleranceBefore,
            toleranceAfter: toleranceAfter
        )
        await updateNowPlayingForSeeking()
        return completed
    }
    
    override public func seek(to date: Date) {
        Task.detached {
            await self.seek(to: date)
        }
    }
    
    @discardableResult
    override public func seek(to date: Date) async -> Bool {
        let completed = await super.seek(to: date)
        await updateNowPlayingForSeeking()
        return completed
    }
}
