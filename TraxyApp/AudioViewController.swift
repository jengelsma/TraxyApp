//
//  AudioViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class AudioViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    var recording = false
    var playing = false
    
    let playImage =  UIImage(named: "play")
    let stopImage = UIImage(named: "stop")
    let recordImage = UIImage(named: "record")
    let pauseImage =  UIImage(named: "pause")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if self.recording {
            self.recordButton.setImage(self.recordImage, for: .normal)
            self.recording = false
        } else {
            self.recordButton.setImage(self.stopImage, for: .normal)
            self.recording = true
        }
    }

    @IBAction func playButtonPressed(_ sender: UIButton) {
        if self.playing {
            self.playButton.setImage(self.playImage, for: .normal)
            self.playing = false
        } else {
            self.playButton.setImage(self.pauseImage, for: .normal)
            self.playing = true
        }
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "setupAudioCaptionForm" {
            if let destCtrl = segue.destination as? JournalEntryConfirmationViewController {
                destCtrl.type = .audio
            }
        }
    }

}
