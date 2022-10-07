//
//  Caption.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 3/23/22.
//

import Foundation
import CoreMedia

/// A structure representing a single caption.
public struct Caption {
    /// The ID of the caption.
    public let id: Int?
    /// The time range for which to display the caption.
    public let displayRange: ClosedRange<VPTime>
    /// The text to display for the caption.
    public let text: String?
}
