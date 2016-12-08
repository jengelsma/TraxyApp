//
//  AudioViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import AVFoundation


class AudioViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    var recording = false
    var playing = false
    
    let playImage =  UIImage(named: "play")
    let stopImage = UIImage(named: "stop")
    let recordImage = UIImage(named: "record")
    
    var entry : JournalEntry?
    var captionEntryCtrl : JournalEntryConfirmationViewController?
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer!
    var meterTimer:Timer!
    var soundFileURL:URL!
    var delegate : AddJournalEntryDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playButton.isEnabled = false
        self.setSessionPlayback()
        if self.entry == nil  {
            self.entry = JournalEntry(key: nil, type: .audio, caption: "", url: nil, date: Date(), lat: 0.0, lng: 0.0)
        }
        
        self.saveButton.isEnabled = false
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if let del = self.delegate {
            
            if let (caption,date,_) = (self.captionEntryCtrl?.extractFormValues()) {
                
                if var e = self.entry {
                    e.url = self.recorder.url.absoluteString
                    e.caption = caption
                    e.date = date
                    del.save(entry: e)
                }
            }
        }
        
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateAudioMeter(_ timer:Timer) {
        
        if self.recorder.isRecording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
            let s = String(format: "%02d:%02d", min, sec)
            self.timeLabel.text = s
            recorder.updateMeters()
        }
    }

    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if self.recording {
            self.recordButton.setImage(self.recordImage, for: .normal)
            self.playButton.isEnabled = true
            self.recording = false
            self.recorder.stop()
        } else {
            self.recordButton.setImage(self.stopImage, for: .normal)
            self.playButton.isEnabled = false
            self.recording = true
            if recorder == nil {
                self.recordWithPermission(true)
            } else {
                self.recordWithPermission(false)
            }
        }
        
        
    }

    @IBAction func playButtonPressed(_ sender: UIButton) {
        if self.playing {
            self.playButton.setImage(self.playImage, for: .normal)
            self.recordButton.isEnabled = true
            self.playing = false
            self.player.pause()
        } else {
            self.playButton.setImage(self.stopImage, for: .normal)
            self.recordButton.isEnabled = false
            self.playing = true
            self.setSessionPlayback()
            self.play()
        }
    }
    
    func play() {
        
        var url:URL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = self.soundFileURL!
        }
        print("playing \(url)")
        
        do {
            self.player = try AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        }
        
    }
    
    func setSessionPlayback() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }

    
    
    func setupRecorder() {
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFileURL!)'")
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        
        let recordSettings:[String : AnyObject] = [
            //AVFormatIDKey:             NSNumber(value: kAudioFormatAppleLossless),
            AVFormatIDKey:             NSNumber(value: kAudioFormatMPEG4AAC),
            AVEncoderAudioQualityKey : NSNumber(value:AVAudioQuality.max.rawValue),
            AVEncoderBitRateKey :      NSNumber(value:320000),
            AVNumberOfChannelsKey:     NSNumber(value:2),
            AVSampleRateKey :          NSNumber(value:44100.0)
        ]
        
        
        do {
            recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }

    
    
    func recordWithPermission(_ setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                           target:self,
                                                           selector:#selector(AudioViewController.updateAudioMeter(_:)),
                                                           userInfo:nil,
                                                           repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "setupAudioCaptionForm" {
            if let destCtrl = segue.destination as? JournalEntryConfirmationViewController {
                destCtrl.type = .audio
                destCtrl.entry = self.entry
                self.captionEntryCtrl = destCtrl
            }
        }
    }

}

// MARK: AVAudioRecorderDelegate
extension AudioViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        self.saveButton.isEnabled = true
        self.recordButton.isEnabled = true
        self.playButton.isEnabled = true
        self.playButton.setImage(self.playImage, for: .normal)
        self.recordButton.setImage(self.recordImage, for: .normal)
        
//        do {
//            let data = try Data(contentsOf: self.recorder.url)
//                    print("got data")
//        } catch {
//            print("oops that wasn't good now")
//        }

        
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    
}

// MARK: AVAudioPlayerDelegate
extension AudioViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
        self.recordButton.isEnabled = true
        self.playButton.isEnabled = true
        self.playButton.setImage(self.playImage, for: .normal)
        self.recordButton.setImage(self.recordImage, for: .normal)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
    
}

