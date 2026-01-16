import UIKit
import AVFoundation
import Accelerate

class UnknownPleasuresViewController: UIViewController {
    
    var engine: AVAudioEngine!
    var player: AVAudioPlayerNode!
    var canResetVolume: Bool = false
    var unknownPleasures: [JoyLine] = []
    
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 2048, vDSP_DFT_Direction.FORWARD)
    
    var targetFftMagnitudes: [Float] = []
    var smoothedFftMagnitudes: [Float] = []
    let smoothing: Float = 0.4
    
    var numberOfLines: Int = 80
    var offsetSize: CGFloat = 5
    
    let hiFrequency: Int = 400
    var rmsValue: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudio()
        
        for i in 0..<numberOfLines {
            unknownPleasures.append(JoyLine(offset: offsetSize * CGFloat(i)))
            unknownPleasures[i].frame = view.bounds
            unknownPleasures[i].backgroundColor = .clear
            
            view.addSubview(unknownPleasures[i])
        }
    
        view.backgroundColor = .black
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        player.volume = 0
        canResetVolume = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        canResetVolume ? (player.volume = 1) : ()
    }
    
    func setupAudio() {
        engine = AVAudioEngine()
        
        _ = engine.mainMixerNode
        
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error)
        }
        
        guard let url = Bundle.main.url(forResource: Songs.disorder.rawValue, withExtension: "mp3") else {
            print("mp3 not found")
            return
        }
        
        player = AVAudioPlayerNode()
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)

            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        } catch let error {
            print(error.localizedDescription)
        }
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 2048, format: nil) {  buffer, time in
            self.processAudioData(buffer: buffer, time: time)
        }
        
        player.play()
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength
        
        targetFftMagnitudes = SignalProcessing.fft(
            data: channelData,
            setup: fftSetup!
        )
        
        if (smoothedFftMagnitudes.isEmpty) {
            smoothedFftMagnitudes = targetFftMagnitudes
        }
        
        for i in 0..<unknownPleasures.count {
            let frequencyBand = Array(targetFftMagnitudes[(hiFrequency / numberOfLines) * i...min((hiFrequency / numberOfLines) * (i + 1), hiFrequency)])
            unknownPleasures[i].rmsChanged(rms: CGFloat(SignalProcessing.rms(data: frequencyBand, frameLength: UInt(frames))))
        }
    }
}

#Preview {
    UnknownPleasuresViewController()
}
