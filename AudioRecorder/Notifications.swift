//
//  Notifications.swift
//  AudioRecorder
//
//  Created by Mayank on 04/06/20.
//  Copyright © 2020 Mayank. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let newAudioFileCreated = Notification.Name("com.audioRecorder.newAudioFileCreated")
    static let newCoughsDetected = Notification.Name("com.audioRecorder.newCoughsDetected")
}
