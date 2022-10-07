//
//  NowPlayingConfiguration.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/1/22.
//

import Foundation

/// A structure representing a configuration of controls to display in the system's now playing module.
public struct NowPlayingConfiguration {
    
    // MARK: - Enums
    /// The supported main controls.
    public enum MainControl {
        case playPause
    }
    
    /// The supported previous controls.
    public enum PreviousControl {
        /// Rewind the track by the time interval specified in ``VelociPlayer/seekInterval``
        case skip
        
        /// Go to the previous track.
        /// - Parameter action: The action to perform when the button is pressed.
        case previousTrack(action: () -> Void)
    }
    
    /// The supported forward controls.
    public enum ForwardControl {
        /// Skip the track forward by the time interval specified in ``VelociPlayer/seekInterval``
        case skip
        
        /// Go to the next track.
        /// - Parameter action: The action to perform when the button is pressed.
        case nextTrack(action: () -> Void)
    }
    
    // MARK: - Variables
    /// Enable or disable scrubbing from the now playing controls.
    public var allowScrubbing: Bool
    
    /// The control that typically appears on the left side of the player indicating going 'back' in some manner.
    /// Defaults to `.skip`
    public var previousControl: PreviousControl?
    
    /// The control that typically appears on the right side of the player indicating going 'forward' in some manner.
    /// Defaults to `.skip`
    public var forwardControl: ForwardControl?
    
    /// The control that typically appears in the center of the player.
    /// Defaults to `.playPause`
    public var mainControl: MainControl
    
    // MARK: - Initialization
    /// Create a configuration for the system player integration.
    public init(
        allowScrubbing: Bool = true,
        previousControl: PreviousControl? = .skip,
        forwardControl: ForwardControl? = .skip,
        mainControl: MainControl = .playPause
    ) {
        self.allowScrubbing = allowScrubbing
        self.previousControl = previousControl
        self.forwardControl = forwardControl
        self.mainControl = mainControl
    }
}
