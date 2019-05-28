//
//  Utils.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/30/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import AVKit

class Utils {
    
    static let shared = Utils()
    
    private var player: AVPlayer!
    
    private init() {
        
    }
    
    // MARK: -

    func keepBackgroundMotionUpdatesRunning() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let path = Bundle.main.path(forResource: "5-seconds-of-silence.mp3", ofType: nil)
        let fileURL = URL(fileURLWithPath: path!)
        player = AVPlayer(url: fileURL)
        player.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player.currentItem,
                                               queue: .main) { [weak self] _ in
                                                self?.player.seek(to: CMTime.zero)
                                                self?.player.play()
        }
    }

}
