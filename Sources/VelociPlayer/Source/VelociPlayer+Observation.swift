//
//  VelociPlayer+Observation.swift
//  
//
//  Created by Ethan Humphrey on 2/22/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Player Observation
    internal func onPlayerTimeChanged(time: CMTime) async {
        await MainActor.run {
            self.progress = time.seconds / duration.seconds
            self.time = time
        }
        await updateCaptions(time: time)
    }
    
    internal func onPlayerTimeControlled() async {
        await MainActor.run {
            switch self.timeControlStatus {
            case .paused:
                self.isPaused = true
                self.isBuffering = false
            case .playing:
                self.isPaused = false
                self.isBuffering = false
            case .waitingToPlayAtSpecifiedRate:
                self.isPaused = false
                self.isBuffering = true
            default:
                break
            }
        }
        
        await updateNowPlayingForSeeking()
    }
    
    internal func statusChanged() async {
        switch self.status {
        case .readyToPlay:
            await MainActor.run {
                prepareForPlayback()
            }
        case .unknown, .failed:
            break
        @unknown default:
            break
        }
    }
    
    internal func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 10_000),
            queue: .main
        ) { [weak self] time in
            Task { [weak self] in
                await self?.onPlayerTimeChanged(time: time)
            }
        }
        
        self.publisher(for: \.timeControlStatus)
            .sink { [weak self] time in
                Task { [weak self] in
                    await self?.onPlayerTimeControlled()
                }
            }
            .store(in: &subscribers)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.progress = 1
                    }
                }
            }
            .store(in: &subscribers)
    }
    
    internal func prepareNewPlayerItem() {
        guard let mediaURL = mediaURL else { return }
        
        let playerItem = AVPlayerItem(url: mediaURL)
        playerItem.preferredForwardBufferDuration = 10
        self.replaceCurrentItem(with: playerItem)
        
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .sink { [weak self] isPlaybackBufferEmpty in
                Task { [weak self] in
                    if isPlaybackBufferEmpty {
                        await self?.bufferStatusChanged(to: .empty)
                    }
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .sink { [weak self] isPlaybackLikelyToKeepUp in
                Task { [weak self] in
                    if isPlaybackLikelyToKeepUp {
                        await self?.bufferStatusChanged(to: .likelyToKeepUp)
                    }
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.isPlaybackBufferFull)
            .sink { [weak self] isPlaybackBufferFull in
                Task { [weak self] in
                    if isPlaybackBufferFull {
                        await self?.bufferStatusChanged(to: .full)
                    }
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.loadedTimeRanges)
            .sink { [weak self] timeRanges in
                Task { [weak self] in
                    await self?.updateBufferTime(timeRanges: timeRanges)
                }
            }
            .store(in: &subscribers)
        
        Task {
            await updateCurrentItemDuration()
        }
    }
}
