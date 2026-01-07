import UIKit
import AVFoundation
import Accelerate
import MetalKit

class ViewController: UIViewController {
    var engine: AVAudioEngine! 
    var audioVisualizer: AudioVisualizer!
    var player: AVAudioPlayerNode!
    
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
        
        guard let url = Bundle.main.url(forResource: Songs.losingMyReligion.rawValue, withExtension: "mp3") else {
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
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { (buffer, time) in
            self.processAudioData(buffer: buffer)
        }
        
        player.play()
    }
    
    var prevRMSValue: Float = 0.3
    
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength
        
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        let interpolatedResults = SignalProcessing.interpolate(current: rmsValue, previous: prevRMSValue)
        prevRMSValue = rmsValue
        
        for rms in interpolatedResults {
            self.audioVisualizer.loudnessMagnitude.scale = rms
        }
        
        let fftMagnitudes = SignalProcessing.fft(
            data: channelData,
            setup: fftSetup!
        )
        
        guard let buffer = self.audioVisualizer.frequencyBuffer else { return }
        let count = min(fftMagnitudes.count,
                        self.audioVisualizer.frequencyVertices.count)

        let ptr = buffer.contents().bindMemory(to: simd_float2.self,
                                               capacity: self.audioVisualizer.frequencyVertices.count)

        for i in 0..<count {
            let angle = Float(i) * 2 * .pi / Float(count)
            let radius = 1.0 + fftMagnitudes[i]

            ptr[i] = simd_float2(
                cos(angle) * radius,
                sin(angle) * radius
            )
        }
        
        updateRotation()
        
        self.audioVisualizer.metalView.draw()
    }
    
    func updateRotation() {
        var rotationAngle: Float = 0
        let rotationSpeed: Float = 0.8
        var lastTimestamp: Float = 0
        
        if let playerNode = self.player {
            let nodeTime = playerNode.lastRenderTime
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime!)
            
            let currentTime = Float(playerTime!.sampleTime) / Float(playerTime!.sampleRate)
            let delta = currentTime - lastTimestamp
            lastTimestamp = currentTime
            
            rotationAngle += rotationSpeed * delta
            rotationAngle = fmod(rotationAngle, 2 * Float.pi)
            
            self.audioVisualizer.rotation = RotationUniform(angle: rotationAngle)
        }
    }
}
