//
//  VelociPlayerError.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/5/22.
//

import Foundation

/// Error codes returned by ``VelociPlayer``.
public enum VelociPlayerError: LocalizedError {
    /// An error indicating that the player encountered an error while attempting to continue loading media.
    case unableToBuffer
    /// An error indicating that the SRT file provided for captions was in the incorrect format and cannot be loaded.
    case invalidSRT
    
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .unableToBuffer:
            return NSLocalizedString("UNABLE_TO_BUFFER_ERROR_DESCRIPTION", bundle: .module, comment: "An error that occurs when the player is unable to buffer the current item.")
        case .invalidSRT:
            return NSLocalizedString("INVALID_SRT_ERROR_DESCRIPTION", bundle: .module, comment: "An error that occurs when the player is unable to decode an SRT file.")
        }
    }
}
