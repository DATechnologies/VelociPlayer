//
//  VelociPlayer+Observation.swift
//  
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Player Observation
    func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds/length.seconds
        self.currentTime = time
    }
    
    func onPlayerTimeControlled() {
        Task {
            switch self.timeControlStatus {
            case .waitingToPlayAtSpecifiedRate, .paused:
                await updateNowPlayingForSeeking(didComplete: false)
            case .playing:
                await updateNowPlayingForSeeking(didComplete: true)
            default:
                break
            }
        }
    }
    
    func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 10000), queue: .main) { [weak self] time in
            self?.onPlayerTimeChanged(time: time)
        }
        
        timeControlSubscriber = self.publisher(for: \.timeControlStatus)
            .sink(receiveValue: { [weak self] time in
                self?.onPlayerTimeControlled()
            })
        
        playEndedSubscriber = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                self?.progress = 1
            }
        
        rateSubscriber = self.publisher(for: \.rate)
            .sink(receiveValue: { [weak self] rate in
                self?.isPaused = rate == 0
            })
    }
}
