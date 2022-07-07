//
//  VelociPlayerError.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/5/22.
//

import Foundation

public enum VelociPlayerError: LocalizedError {
    case unableToBuffer
    case invalidSRT
    
    public var errorDescription: String? {
        switch self {
        case .unableToBuffer:
            return NSLocalizedString("UNABLE_TO_BUFFER_ERROR_DESCRIPTION", bundle: .module, comment: "An error that occurs when the player is unable to buffer the current item.")
        case .invalidSRT:
            return NSLocalizedString("INVALID_SRT_ERROR_DESCRIPTION", bundle: .module, comment: "An error that occurs when the player is unable to decode an SRT file.")
        }
    }
}
