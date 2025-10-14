//
//  PostureType.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


//
//  PostureTypes.swift
//  sitRight-Posture
//
//  Put this in Models folder
//

import SwiftUI

/// An enumeration representing the different types of posture issues that can be analyzed.
enum PostureType: String, CaseIterable {
    /// Represents forward head posture, where the head juts forward.
    case forwardHead = "Forward Head Posture"
    /// Represents rounded shoulders, where the shoulders are hunched forward.
    case roundedShoulder = "Rounded Shoulders"
    /// Represents back slouch, or excessive thoracic kyphosis.
    case backSlouch = "Back Slouch"
}