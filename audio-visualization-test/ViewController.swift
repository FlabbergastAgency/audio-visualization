import UIKit
import AVFoundation
import Accelerate
import MetalKit

class ViewController: UIViewController {
    var engine: AVAudioEngine! 
    var audioVisualizer: AudioVisualizer!
    var player: AVAudioPlayerNode!
    
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 2048, vDSP_DFT_Direction.FORWARD)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioVisualizer = AudioVisualizer()
        view.addSubview(audioVisualizer)
        
        audioVisualizer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        audioVisualizer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        audioVisualizer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        audioVisualizer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        setupAudio()
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
        
        guard let url = Bundle.main.url(forResource: Songs.veridisQuo.rawValue, withExtension: "mp3") else {
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
        
        let fftMagnitudes = SignalProcessing.fft(
            data: channelData,
            setup: fftSetup!
        )
        
        let loFrequency: Int = 0
        let hiFrequency: Int = 1023
        let frequencyBand = Array(fftMagnitudes[loFrequency...hiFrequency])
        
        let rmsValue = SignalProcessing.rms(data: frequencyBand, frameLength: UInt(frames))
        audioVisualizer.targetScale = rmsValue
        
        let count = min(fftMagnitudes.count,
                        self.audioVisualizer.frequencyVertices.count)

        let ptr = audioVisualizer.frequencyBuffer.contents().bindMemory(to: simd_float2.self,
                                               capacity: self.audioVisualizer.frequencyVertices.count)

        for i in 0..<count {
            let angle = Float(i) * 2 * .pi / Float(count)
            let radius = 1.0 + fftMagnitudes[i]

            ptr[i] = simd_float2(
                cos(angle) * radius,
                sin(angle) * radius
            )
        }
    }
}
