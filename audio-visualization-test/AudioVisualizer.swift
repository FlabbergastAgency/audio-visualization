import UIKit
import MetalKit
import simd

struct LoudnessUniform {
    var scale: Float
    var aspectRatio: Float
}

struct RotationUniform {
    var angle: Float
    var rotationMatrix: matrix_float2x2
    
    init(angle: Float) {
        self.angle = angle
        self.rotationMatrix = matrix_float2x2(
            columns: (
                simd_float2(cos(angle), sin(angle)),
                simd_float2(-sin(angle), cos(angle))
            )
        )
    }
}

class AudioVisualizer: UIView {
    
    public var metalView: MTKView!
    private var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var metalRenderPipelineState: MTLRenderPipelineState!
    
    private var circleVertices = [simd_float2]()
    private var vertexBuffer: MTLBuffer!
    
    private var loudnessUniformBuffer: MTLBuffer!
    public var loudnessMagnitude: LoudnessUniform = LoudnessUniform(scale: 0.3, aspectRatio: 1.0)
    
    private var rotationUniformBuffer: MTLBuffer!
    public var rotation: RotationUniform = RotationUniform(angle: 0.0)
    
    public var frequencyBuffer: MTLBuffer!
    public var frequencyVertices: [simd_float2] = []
    
    public required init() {
        super.init(frame: .zero)
        setupView()
        createVertexPoints()
        setupMetal()
    }
    
    public required init? (coder aDecoder: NSCoder) {
        fatalError()
    }
    
    fileprivate func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    fileprivate func setupMetal() {
        metalView = MTKView()
        addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        metalView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        metalView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        metalView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        metalView.delegate = self
        
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = false
        
        metalDevice = MTLCreateSystemDefaultDevice()
        metalView.device = metalDevice
        
        metalCommandQueue = metalDevice.makeCommandQueue()!
        
        createPipelineState()
        
        vertexBuffer = metalDevice.makeBuffer(bytes: circleVertices,
                                              length: circleVertices.count * MemoryLayout<simd_float2>.stride,
                                              options: [])!
        
        loudnessUniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<LoudnessUniform>.stride,
                                                       options: [])!
        
        rotationUniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<RotationUniform>.stride,
                                                       options: [])
        
        frequencyVertices = Array(repeating: .zero, count: 361)
        frequencyBuffer = metalDevice.makeBuffer(bytes: frequencyVertices,
                                                 length: frequencyVertices.count * MemoryLayout<simd_float2>.stride,
                                                 options: [])!
        
        metalView.draw()
    }
    
    fileprivate func createPipelineState() {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()!
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        metalRenderPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    fileprivate func createVertexPoints() {
        func rads(forDegree d: Float) -> Float32 {
            return (Float.pi*d)/180.0
        }
        
        let origin = simd_float2(0, 0)
        
        for i in 0...720 {
            let position : simd_float2 = [cos(rads(forDegree: Float(Float(i)/2.0))),sin(rads(forDegree: Float(Float(i)/2.0)))]
            circleVertices.append(position)
            if (i+1) % 2 == 0 {
                circleVertices.append(origin)
            }
        }
    }
}

extension AudioVisualizer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        loudnessMagnitude.aspectRatio = Float(metalView.drawableSize.width / metalView.drawableSize.height)
        
        memcpy(
            loudnessUniformBuffer.contents(),
            &loudnessMagnitude,
            MemoryLayout<LoudnessUniform>.stride
        )
        
        memcpy(
            rotationUniformBuffer.contents(),
            &rotation,
            MemoryLayout<RotationUniform>.stride
        )

        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else { return }
        
        guard let renderDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(metalRenderPipelineState)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(loudnessUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(rotationUniformBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: circleVertices.count)
        
        renderEncoder.setVertexBuffer(frequencyBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(loudnessUniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: frequencyVertices.count)
        
        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
