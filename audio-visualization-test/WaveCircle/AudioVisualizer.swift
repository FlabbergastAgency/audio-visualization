import UIKit
import MetalKit
import simd

struct Vertex {
    var position: simd_float2
    var textureCoordinate: simd_float2
}

struct Uniform {
    var scale: Float
    var aspectRatio: Float
    var rotationMatrix: matrix_float2x2
}

class AudioVisualizer: UIView {
    
    public var metalView: MTKView!
    private var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var metalRenderPipelineState: MTLRenderPipelineState!
    
    private var circleVertices: [Vertex] = []
    private var vertexBuffer: MTLBuffer!
    
    private var uniformBuffer: MTLBuffer!
    
    public var targetScale: Float = 0.15
    private var rotationAngle: Float = 0
    private var smoothedScale: Float = 0.15
    private var smoothedRotation: Float = 0
    
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    
    public var frequencyBuffer: MTLBuffer!
    public var frequencyVertices: [simd_float2] = []
    
    private var albumTexture: MTLTexture!
    
    private var albumCover: UIImage = UIImage(named: "oot")!
    
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
        
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = false
        metalView.preferredFramesPerSecond = 60
        
        metalDevice = MTLCreateSystemDefaultDevice()
        metalView.device = metalDevice
        
        metalCommandQueue = metalDevice.makeCommandQueue()!
        
        createPipelineState()
        
        vertexBuffer = metalDevice.makeBuffer(bytes: circleVertices,
                                              length: circleVertices.count * MemoryLayout<Vertex>.stride,
                                              options: [])!
        
        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<Uniform>.stride,
                                                       options: [])!
        
        frequencyVertices = Array(repeating: .zero, count: 361)
        frequencyBuffer = metalDevice.makeBuffer(bytes: frequencyVertices,
                                                 length: frequencyVertices.count * MemoryLayout<simd_float2>.stride,
                                                 options: [])!
        
        loadAlbumTexture(image: albumCover)
    }
    
    fileprivate func createPipelineState() {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()!
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        pipelineDescriptor.vertexDescriptor = makeVertexDescriptor()

        metalRenderPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    fileprivate func createVertexPoints() {
        func rads(forDegree d: Float) -> Float32 {
            return (Float.pi*d)/180.0
        }
        
        let origin = simd_float2(0, 0)
        
        for i in 0...720 {
            let angle = Float(i) * 0.5
            let x = cos(rads(forDegree: angle))
            let y = sin(rads(forDegree: angle))
            
            let pos = simd_float2(x, y)
            
            let u = (x + 1) * 0.5
            let v = 1.0 - ((y + 1) * 0.5)
            
            let uv = simd_float2(u, v)
            
            circleVertices.append(Vertex(position: pos, textureCoordinate: uv))
            
            if (i + 1) % 2 == 0 {
                circleVertices.append(Vertex(position: origin, textureCoordinate: simd_float2(0.5, 0.5)))
            }
        }
    }
}

extension AudioVisualizer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        
        let now = CACurrentMediaTime()
        let delta = Float(now - lastFrameTime)
        lastFrameTime = now

        let rotationSpeed: Float = 0.8
        rotationAngle += rotationSpeed * delta

        let smoothing: Float = 0.12
        smoothedScale += (targetScale - smoothedScale) * smoothing
        if smoothedScale < 0.15 { smoothedScale = 0.15 }
        if smoothedScale > 3.0 { smoothedScale = 3.0 }
        smoothedRotation += (rotationAngle - smoothedRotation) * smoothing

        let rotationMatrix = matrix_float2x2(
            columns: (
                simd_float2(cos(smoothedRotation), sin(smoothedRotation)),
                simd_float2(-sin(smoothedRotation), cos(smoothedRotation))
            )
        )

        var uniform = Uniform(
            scale: smoothedScale,
            aspectRatio: Float(view.drawableSize.width / view.drawableSize.height),
            rotationMatrix: rotationMatrix
        )
        
        memcpy(
            uniformBuffer.contents(),
            &uniform,
            MemoryLayout<Uniform>.stride
        )

        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else { return }
        
        guard let renderDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(metalRenderPipelineState)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(albumTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: circleVertices.count)
        
        renderEncoder.setVertexBuffer(frequencyBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: frequencyVertices.count)
        
        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func loadAlbumTexture(image: UIImage) {
        let loader = MTKTextureLoader(device: self.metalDevice)
        let options: [MTKTextureLoader.Option : Any] = [.SRGB: false]
        
        albumTexture = try? loader.newTexture(
            cgImage: image.cgImage!,
            options: options
        )
    }
    
    func makeVertexDescriptor() -> MTLVertexDescriptor {

        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<simd_float2>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        return vertexDescriptor
    }

}
