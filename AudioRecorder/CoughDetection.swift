//
//  CoughDetection.swift
//  AudioRecorder
//
//  Created by Mayank on 03/06/20.
//  Copyright © 2020 Mayank. All rights reserved.
//

import AVFoundation
import CoreData
import CoreML
import Foundation
import UIKit

/// Class: CoughDetection
/// This class performs the classification based on the machine learning algorithm.

class CoughDetection {
    private static let sharedCoughDetectionObject = CoughDetection()

    /// Instance Variables
    let coughModel = CoughModel()
    var audioFiles: [URL] = []
    var coughCount = 0

    private init() {
        registerForNotifications()
    }

    class func shared() -> CoughDetection {
        return sharedCoughDetectionObject
    }

    /// Register Observer to catch notifications, everytime a new audio file is created.
    func registerForNotifications() {
        NotificationCenter.default.addObserver(
            forName: .newAudioFileCreated,
            object: nil,
            queue: nil
        ) { notification in
            if let uInfo = notification.userInfo {
                let file = uInfo["audioFileName"]
                self.audioFiles.append(file as! URL)
            }
        }
    }

    /// Process all the audio files that were created and clear them from queue
    func processCoughDetection() {
        DispatchQueue.main.async {
            for file in self.audioFiles {
                self.readAudioFile(audioFileURL: file.description) { count in
                    if count > 0 {
                        NotificationCenter.default.post(name: .newCoughsDetected,
                                                        object: self,
                                                        userInfo: ["coughCount": count])
                        self.save(fileName: file.absoluteString, coughCount: count)
                    }
                }
            }
            self.audioFiles.removeAll()
        }
    }

    func save(fileName: String, coughCount: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        // 1
        let managedContext = appDelegate.persistentContainer.viewContext
        // 2
        let entity = NSEntityDescription.entity(forEntityName: "CoughSession", in: managedContext)!
        let session = NSManagedObject(entity: entity, insertInto: managedContext)
        /// Storing data into NSManagedContext
        session.setValue(fileName, forKeyPath: "file")
        session.setValue(coughCount, forKeyPath: "count")
        session.setValue(Date(), forKeyPath: "date")
        do { try managedContext.save() } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    /// Use the CoreML Model to detect coughs by splitting the input file into chunks of 15648 samples.
    func readAudioFile(audioFileURL: String, completion: @escaping (Int) -> Void) {
        var coughCount: Int = 0
        var wav_file: AVAudioFile!
        do {
            let fileUrl = URL(string: audioFileURL)!
            wav_file = try AVAudioFile(forReading: fileUrl)
        } catch {
            fatalError("Could not open wav file.")
        }

        /// Check that the audio file's sample rate is 16KHz
        assert(wav_file.fileFormat.sampleRate == 16000.0, "Sample rate is not right!")

        let buffer = AVAudioPCMBuffer(pcmFormat: wav_file.processingFormat,
                                      frameCapacity: UInt32(wav_file.length))
        do {
            try wav_file.read(into: buffer!)
        } catch {
            fatalError("Error reading buffer.")
        }
        guard let bufferData = try buffer?.floatChannelData else {
            fatalError("Can not get a float handle to buffer")
        }
        let windowSize = 15648
        guard let audioData = try? MLMultiArray(shape: [1, windowSize as NSNumber],
                                                dataType: MLMultiArrayDataType.float32)
        else {
            fatalError("Can not create MLMultiArray")
        }
        let frameLength = Int(buffer!.frameLength)
        var audioDataIndex = 0

        /// Iterate over all the samples, chunking calls to analyze every 15648
        for i in 0 ..< frameLength {
            audioData[audioDataIndex] = NSNumber(value: bufferData[0][i])
            if audioDataIndex >= windowSize {
                guard let modelOutput = try? coughModel.prediction(input_1: audioData) else {
                    fatalError("Error calling predict")
                }

                DispatchQueue.main.async {
                    print("\t\t \(modelOutput.Identity[0].floatValue)")
                    if modelOutput.Identity[0].floatValue > 0.5 {
                        coughCount += 1
                    }
                }
                audioDataIndex = 0
            } else {
                audioDataIndex += 1
            }
        }
        DispatchQueue.main.async {
            completion(coughCount)
        }
    }
}
