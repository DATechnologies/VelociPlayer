//
//  NowPlayingConfiguration.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/1/22.
//

import Foundation

public struct NowPlayingConfiguration {
    
    // MARK: - Enums
    public enum MainControl {
        case playPause
    }
    
    public enum PreviousControl {
        case skip
        case previousTrack(action: () -> Void)
    }
    
    public enum ForwardControl {
        case skip
        case nextTrack(action: () -> Void)
    }
    
    // MARK: - Variables
    /// Enable or disable scrubbing from the now playing controls.
    public var allowScrubbing: Bool
    
    /// The control that typically appears on the left side of the player indicating going 'back' in some manner.
    public var previousControl: PreviousControl?
    
    /// The control that typically appears on the right side of the player indicating going 'forward' in some manner.
    public var forwardControl: ForwardControl?
    
    /// The control that typically appears in the center of the player.
    public var mainControl: MainControl
    
    // MARK: - Initialization
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
