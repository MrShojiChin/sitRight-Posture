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

// MARK: - Posture Type (Single definition for entire app)
enum PostureType: String, CaseIterable {
    case forwardHead = "Forward Head Posture"
    case roundedShoulder = "Rounded Shoulders"
    case backSlouch = "Back Slouch"
}