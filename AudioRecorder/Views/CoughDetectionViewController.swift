//
//  ViewController.swift
//  AudioRecorder
//
//  Created by Mayank on 19/05/20.
//  Copyright © 2020 Mayank. All rights reserved.
//

import AVFoundation
import CoreML
import UIKit

class CoughDetectionViewController: UIViewController, AVAudioRecorderDelegate {
    /// Session Variables
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
//    var micTracker: AKMicrophoneTracker!

    /// UI Outlet Components
    @IBOutlet var AmplitudeLabel: UILabel!
    @IBOutlet var maxAmplLabel: UILabel!
    @IBOutlet var coughDetectedLabel: UILabel!
    @IBOutlet var recordSwitch: UISwitch!

    /// ViewModel variables.
    var maxAmp: Double = 0
    var tracker: Timer?
    var files: [String] = []
    var numberCoughs: Int = 0
    var currentAudioFilename = URL(string: "www.httos.com")!
    var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    override func viewDidLoad() {
        AmplitudeLabel.text = "0.0"
        maxAmplLabel.text = "0.0"
        coughDetectedLabel.text = "0"
        recordSwitch.setOn(false, animated: true)

        setupCoughDetectionObserver()
        setupAudioSession()
    }

    fileprivate func setupAudioSession() {
        // Additional setup after loading the view.
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.record, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording Allowed")
                    } else {
                        print("Recording Not Allowed")
                    }
                }
            }
        } catch {
            print("Recording Permissions check Failed")
        }
    }

    fileprivate func setupCoughDetectionObserver() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: .newCoughsDetected,
            object: nil,
            queue: nil
        ) { notification in
            if let uInfo = notification.userInfo {
                var newCoughsDetected: Int = uInfo["coughCount"] as! Int
                self.numberCoughs += newCoughsDetected
                self.coughDetectedLabel.text = self.numberCoughs.description
            }
        }
    }

    func startRecording() {
        let audioFileSuffix = UUID().description + "recording.m4a"
        currentAudioFilename = documentsDirectory.appendingPathComponent(audioFileSuffix)
        print(currentAudioFilename)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: currentAudioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
//            DispatchQueue.main.async {
//                self.tracker = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.runTimedCode), userInfo: nil, repeats: true)
//            }
//            micTracker = AKMicrophoneTracker(hopSize: 4096, peakCount: 20)
//            micTracker.start()
        } catch {
            print("UNSUCCESSSFUL")
            finishRecording(success: false)
        }
    }

//    @objc func runTimedCode() {
//        AmplitudeLabel.text = micTracker.amplitude.description
//        if micTracker.amplitude > maxAmp {
//            maxAmp = micTracker.amplitude
//            maxAmplLabel.text = maxAmp.description
//        }
//    }

    @IBAction func detectCoughPressed(_: Any) {
        CoughDetection.shared().processCoughDetection()
    }

    @IBAction func switchPressed(_: Any) {
        if recordSwitch.isOn == true {
            startRecording()
        } else {
            finishRecording(success: true)
            AmplitudeLabel.text = "0.00"
        }
    }

    func finishRecording(success: Bool) {
        tracker?.invalidate()
        maxAmp = 0

        if audioRecorder != nil {
//            micTracker.stop()
            audioRecorder.stop()
            NotificationCenter.default.post(name: .newAudioFileCreated,
                                            object: self,
                                            userInfo: ["audioFileName": currentAudioFilename])
            audioRecorder = nil
        }
        if success {
            print("RECORDING SUCCESS")
        } else {
            print("RECORDING FAILED")
        }
    }

    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }

    func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
