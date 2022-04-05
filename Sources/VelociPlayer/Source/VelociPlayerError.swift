//
//  VelociPlayerError.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/5/22.
//

import Foundation

public enum VelociPlayerError: LocalizedError {
    case invalidSRT
    
    public var errorDescription: String? {
        switch self {
        case .invalidSRT:
            return NSLocalizedString("INVALID_SRT_ERROR_DESCRIPTION", comment: "Invalid SRT Error Description")
        }
    }
}
