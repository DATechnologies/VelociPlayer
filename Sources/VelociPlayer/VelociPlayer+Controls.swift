//
//  VelociPlayer+Controls.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Controls
    
    /// Begins playback of the current item
    public override func play() {
        if subscribers.isEmpty {
            startObservingPlayer()
            setAVCategory()
        }
        super.play()
    }
    
    /// Rewind the player based on the `seekInterval`
    public func rewind() {
        let newTime = currentTime().seconds - self.seekInterval
        seek(to: newTime)
    }
    
    /// Go forward based on the `seekInterval`
    public func skipForward() {
        let newTime = currentTime().seconds + self.seekInterval
        seek(to: newTime)
    }
    
    /// Toggles playback for the current item.
    public func togglePlayback() {
        if isPaused {
            play()
        } else {
            pause()
        }
    }
    
    /// Stop playback and end any observation on the player.
    public func stop() {
        if let timeObserver = timeObserver, timeControlStatus == .playing {
            self.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        subscribers.removeAll()
        
        self.nowPlayingInfo = nil
        self.pause()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[VelociPlayer] Error while communicating with AVAudioSession", error.localizedDescription)
        }
    }
}
