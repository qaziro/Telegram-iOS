// LiquidGlassRenderer.swift

import UIKit
import Metal
import MetalKit
import simd

public struct LiquidGlassParameters: Equatable {
    public var isGlassColorEnabled: Bool = true
    public var glassColor: UIColor = .black.withAlphaComponent(0.02)
    
    public var isLightingEnabled: Bool = false
    public var lightAngle: Float = -0.785
    public var lightIntensity: Float = 2.5
    public var ambientStrength: Float = 0.1
    
    public var isRefractionEnabled: Bool = true
    public var thickness: Float = 37.0
    public var refractiveIndex: Float = 0.035
    public var chromaticAberration: Float = 0.05
    public var lensDome: Float = 2.2
    
    public var isBlurEnabled: Bool = false
    public var blurRadius: Float = 4.0
    
    public var blend: Float = 80.0
    
    public var glowEnabled: Bool = false
    public var glowCenter: CGPoint = .zero
    public var glowRadius: Float = 0.0
    public var glowIntensity: Float = 0.0
    public var glowColor: UIColor = .cyan
    
    public var dispersionStrength: Float = 0.0
    
    public var textureIndex: Int = 0
    public var layerUVOffset: CGPoint = .zero
    public var layerUVScale: CGPoint = CGPoint(x: 1.0, y: 1.0)
    
    public var opticalPassThrough: Float = 1.0

    public init() {}
    
    func toFloatArray() -> [Float] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        glassColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var gr: CGFloat = 0, gg: CGFloat = 0, gb: CGFloat = 0, ga: CGFloat = 0
        glowColor.getRed(&gr, green: &gg, blue: &gb, alpha: &ga)
        
        return [
            /* 0-3 */   Float(r), Float(g), Float(b), Float(a),
            /* 4-6 */   lightAngle, lightIntensity, ambientStrength,
            /* 7-10 */  thickness, refractiveIndex, chromaticAberration, isBlurEnabled ? blurRadius : 0.0,
            /* 11-12 */ blend, lensDome,
            /* 13-17 */ isRefractionEnabled ? 1.0 : 0.0, isLightingEnabled ? 1.0 : 0.0, isGlassColorEnabled ? 1.0 : 0.0, isBlurEnabled ? 1.0 : 0.0, glowEnabled ? 1.0 : 0.0,
            /* 18-24 */ Float(glowCenter.x), Float(glowCenter.y), glowRadius, glowIntensity, Float(gr), Float(gg), Float(gb),
            /* 25 */    dispersionStrength,
            /* 26 */    Float(textureIndex),
            /* 27-28 */ Float(layerUVOffset.x), Float(layerUVOffset.y),
            /* 29-30 */ Float(layerUVScale.x), Float(layerUVScale.y),
            /* 31 */    opticalPassThrough
        ]
    }
}

public enum LiquidShapeType: Float {
    case squircle = 1.0
}

public struct ShapeData: Equatable {
    var type: LiquidShapeType = .squircle
    var x: Float
    var y: Float
    var width: Float
    var height: Float
    var cornerRadius: Float
    var layerID: Float
    
    public init(type: LiquidShapeType = .squircle, x: Float, y: Float, width: Float, height: Float, cornerRadius: Float, layerID: Float) {
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.layerID = layerID
    }
    
    func toFloatArray() -> [Float] {
        return [type.rawValue, x, y, width, height, cornerRadius, layerID, 0.0]
    }
}

public struct ShadowCaster: Equatable {
    public var color: SIMD4<Float>
    public var center: SIMD2<Float>
    public var size: SIMD2<Float>
    public var offset: SIMD2<Float>
    public var radius: Float
    public var cornerRadius: Float
    
    public init(color: UIColor, center: CGPoint, size: CGSize, offset: CGSize, radius: CGFloat, cornerRadius: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.color = SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
        self.center = SIMD2<Float>(Float(center.x), Float(center.y))
        self.size = SIMD2<Float>(Float(size.width * 2.0), Float(size.height * 2.0))
        self.offset = SIMD2<Float>(Float(offset.width), Float(offset.height))
        self.radius = Float(radius) * 2.0
        self.cornerRadius = Float(cornerRadius)
    }
}

public enum LiquidRenderMode {
    case manual
    case automatic
    case continuous
}

public final class BackgroundTextureProvider {
    private weak var targetView: UIView?
    private let device: MTLDevice
    
    public private(set) var cachedTexture: MTLTexture?
    private var pixelBuffer: UnsafeMutableRawPointer?
    private var pixelBufferBytesPerRow: Int = 0
    private var pixelBufferHeight: Int = 0
    private var pixelBufferWidth: Int = 0
    
    public var captureScale: CGFloat = UIScreen.main.scale
    public var useDrawHierarchy: Bool = false
    
    private lazy var debugTexture: MTLTexture? = { return createDebugCheckerboardTexture() }()

    public init(device: MTLDevice) {
        self.device = device
    }
    
    deinit { if let buffer = pixelBuffer { free(buffer) } }

    public func invalidate() { cachedTexture = nil }

    public func texture(for view: UIView, shouldUpdate: Bool) -> MTLTexture? {
        if targetView !== view { targetView = view }
        
        if shouldUpdate || cachedTexture == nil {
            let startTime = CFAbsoluteTimeGetCurrent()
            updateTexture(from: view)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            #if DEBUG
            RenderPerformanceMonitor.shared.logSnapshotDuration(duration)
            #endif
        }
        return cachedTexture ?? debugTexture
    }

    public func applyManualSnapshot(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow
        
        ensureBufferSize(width: width, height: height, bytesPerRow: bytesPerRow, bufferSize: bufferSize)
        guard let buffer = pixelBuffer else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext(data: buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return }
        
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        updateTextureFromBuffer(width: width, height: height, bytesPerRow: bytesPerRow)
    }
    
    public func createTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        if width == 0 || height == 0 { return nil }
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow
        
        guard let buffer = malloc(bufferSize) else { return nil }
        defer { free(buffer) }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext(data: buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: bytesPerRow)
        
        return texture
    }
    
    private func updateTexture(from glass: UIView) {
        guard let window = glass.window else { return }
        let rectInWindow = glass.convert(glass.bounds, to: window)
        let scale = self.captureScale
        let width = Int(rectInWindow.width * scale)
        let height = Int(rectInWindow.height * scale)
        if width < 1 || height < 1 { return }
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow
        ensureBufferSize(width: width, height: height, bytesPerRow: bytesPerRow, bufferSize: bufferSize)
        guard let buffer = pixelBuffer else { return }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext(data: buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return }
        context.clear(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -rectInWindow.origin.x, y: -rectInWindow.origin.y)
        let wasHidden = glass.isHidden
        glass.isHidden = true
        if useDrawHierarchy {
            UIGraphicsPushContext(context)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        } else {
            window.layer.render(in: context)
        }
        glass.isHidden = wasHidden
        updateTextureFromBuffer(width: width, height: height, bytesPerRow: bytesPerRow)
    }
    
    private func ensureBufferSize(width: Int, height: Int, bytesPerRow: Int, bufferSize: Int) {
        if pixelBuffer == nil || pixelBufferWidth != width || pixelBufferHeight != height {
            if let existing = pixelBuffer { free(existing) }
            pixelBuffer = malloc(bufferSize)
            pixelBufferWidth = width; pixelBufferHeight = height; pixelBufferBytesPerRow = bytesPerRow
            cachedTexture = nil
        }
    }
    
    private func updateTextureFromBuffer(width: Int, height: Int, bytesPerRow: Int) {
        guard let buffer = pixelBuffer else { return }
        if let texture = cachedTexture, texture.width == width, texture.height == height {
            let region = MTLRegionMake2D(0, 0, width, height)
            texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: bytesPerRow)
        } else {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.usage = [.shaderRead]
            guard let newTexture = device.makeTexture(descriptor: descriptor) else { return }
            let region = MTLRegionMake2D(0, 0, width, height)
            newTexture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: bytesPerRow)
            cachedTexture = newTexture
        }
    }
    
    private func createDebugCheckerboardTexture() -> MTLTexture? {
        let width = 64; let height = 64; let bytesPerPixel = 4
        var bytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * bytesPerPixel
                let isMagenta = ((x / 8) + (y / 8)) % 2 == 0
                if isMagenta { bytes[index] = 255; bytes[index+1] = 0; bytes[index+2] = 255; bytes[index+3] = 255 }
                else { bytes[index] = 0; bytes[index+1] = 255; bytes[index+2] = 0; bytes[index+3] = 255 }
            }
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: width * bytesPerPixel)
        return texture
    }
}

fileprivate struct Uniforms {
    var size: SIMD2<Float>
    var shapeCount: Int32
    var paramCount: Int32
    var shadowCasterCount: Int32
    var maxLayerIndex: Float
    var textureOffset: SIMD2<Float>
    var uvScale: SIMD2<Float>
}

open class LiquidGlassUIView: UIView {
    public var renderMode: LiquidRenderMode = .automatic {
        didSet { displayLink?.isPaused = (renderMode == .manual) }
    }
    public var isManualBackgroundMode: Bool = false
    public var automaticallyRenderOnLayout: Bool = true
    public var canUpdateSnapshotCallback: (() -> Bool)?
    
    public var useDrawHierarchy: Bool {
        get { return backgroundProvider?.useDrawHierarchy ?? true }
        set { backgroundProvider?.useDrawHierarchy = newValue }
    }
    
    public var shapes: [ShapeData] = []
    public var layerParameters: [LiquidGlassParameters] = []
    public var shadowCasters: [ShadowCaster] = []
    public var textureOffset: CGPoint = .zero
    public var textureUvScale: CGPoint = CGPoint(x: 1.0, y: 1.0)
    
    public var additionalTextures: [Int: MTLTexture] = [:] {
        didSet { if renderMode == .manual { isDirty = true } }
    }

    private var metalView: MTKView!
    private var coordinator: MetalCoordinator!
    public var backgroundProvider: BackgroundTextureProvider?
    
    private var displayLink: CADisplayLink?
    private var activityTimer: Timer?
    private var isAwake: Bool = false
    private var isDirty: Bool = true
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        displayLink?.invalidate()
        activityTimer?.invalidate()
    }
    
    public func setTexture(_ texture: MTLTexture?, forSlot slot: Int) {
        if slot <= 0 { return }
        if let texture = texture {
            additionalTextures[slot] = texture
        } else {
            additionalTextures.removeValue(forKey: slot)
        }
        if renderMode == .manual { render() }
    }
    
    public func render() {
        isDirty = true
        if renderMode == .manual { metalView.draw() }
    }
    
    public func render(updateSnapshot: Bool) {
        isDirty = true
        coordinator.shouldUpdateBackgroundSnapshot = updateSnapshot
        metalView.draw()
    }
    
    public func forceRender() {
        isDirty = true
        coordinator.shouldUpdateBackgroundSnapshot = !isManualBackgroundMode
        metalView.draw()
    }

    public func wakeUp(duration: TimeInterval = 0.6) {
        self.isAwake = true
        self.activityTimer?.invalidate()
        self.activityTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.isAwake = false
        }
        render()
    }
    
    public func startAnimating() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkTick))
            displayLink?.add(to: .main, forMode: .common)
        }
        displayLink?.isPaused = (renderMode == .manual)
    }
    
    public func stopAnimating() {
        displayLink?.isPaused = true
        activityTimer?.invalidate()
        isAwake = false
    }

    private func setupView() {
        backgroundColor = .clear
        clipsToBounds = true
        setupMetalView()
        startAnimating()
    }

    private func setupMetalView() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        metalView = MTKView(frame: bounds, device: device)
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalView.isOpaque = false
        metalView.backgroundColor = .clear
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metalView)
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        backgroundProvider = BackgroundTextureProvider(device: device)
        coordinator = MetalCoordinator(device: device)
        coordinator.backgroundProvider = backgroundProvider
        coordinator.parentView = self
        metalView.delegate = coordinator
    }

    @objc private func displayLinkTick() {
        if renderMode == .manual { return }
        var needsSnapshot = false
        var needsDraw = false
        
        switch renderMode {
        case .continuous:
            needsSnapshot = !isManualBackgroundMode
            needsDraw = true
        case .automatic:
            let isUpdatePermitted = canUpdateSnapshotCallback?() ?? true
            if isUpdatePermitted {
                let isScrolling = RunLoop.current.currentMode == .tracking
                let isActive = isScrolling || self.isAwake
                needsSnapshot = isActive && !isManualBackgroundMode
            } else { needsSnapshot = false }
            needsDraw = needsSnapshot || isDirty
        case .manual: break
        }
        
        if needsDraw {
            coordinator.shouldUpdateBackgroundSnapshot = needsSnapshot
            metalView.draw()
            isDirty = false
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if !automaticallyRenderOnLayout { return }
        if renderMode != .manual { wakeUp(duration: 0.2) } else { forceRender() }
    }
}

private class MetalCoordinator: NSObject, MTKViewDelegate {
    weak var parentView: LiquidGlassUIView?
    var backgroundProvider: BackgroundTextureProvider?
    var shouldUpdateBackgroundSnapshot = false
    
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var device: MTLDevice!
    private var shapeDataBuffer: MTLBuffer?
    private var paramDataBuffer: MTLBuffer?
    private var shadowCasterBuffer: MTLBuffer?

    init(device: MTLDevice) {
        self.device = device
        super.init()
        setupMetal()
    }

    private func setupMetal() {
        commandQueue = device.makeCommandQueue()!
        
        let library: MTLLibrary
        let bundle = Bundle(for: LiquidGlassUIView.self)

        if let bundleLibrary = try? device.makeDefaultLibrary(bundle: bundle) {
            library = bundleLibrary
        } else if let defaultLibrary = device.makeDefaultLibrary() {
            library = defaultLibrary
        } else {
            fatalError("Could not create Metal library from bundle or system default.")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexPassthrough")
        descriptor.fragmentFunction = library.makeFunction(name: "liquidGlassFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    private func updateBuffers(for view: MTKView) {
        guard let parent = parentView else {
            shapeDataBuffer = nil; paramDataBuffer = nil; shadowCasterBuffer = nil
            return
        }
        let scale = view.layer.contentsScale
        
        if !parent.shapes.isEmpty {
            let shapeFloats = parent.shapes.flatMap { shape -> [Float] in
                var scaledShape = shape
                scaledShape.x *= Float(scale)
                scaledShape.y *= Float(scale)
                scaledShape.width *= Float(scale)
                scaledShape.height *= Float(scale)
                scaledShape.cornerRadius *= Float(scale)
                return scaledShape.toFloatArray()
            }
            shapeDataBuffer = device.makeBuffer(bytes: shapeFloats, length: shapeFloats.count * MemoryLayout<Float>.size, options: [.storageModeShared])
        } else { shapeDataBuffer = nil }
        
        if !parent.layerParameters.isEmpty {
             let paramFloats = parent.layerParameters.flatMap { params -> [Float] in
                var scaledParams = params
                scaledParams.glowCenter.x *= scale
                scaledParams.glowCenter.y *= scale
                scaledParams.glowRadius *= Float(scale)
                return scaledParams.toFloatArray()
            }
            paramDataBuffer = device.makeBuffer(bytes: paramFloats, length: paramFloats.count * MemoryLayout<Float>.size, options: [.storageModeShared])
        } else { paramDataBuffer = nil }
        
        if !parent.shadowCasters.isEmpty {
            var scaledCasters = parent.shadowCasters
            for i in 0..<scaledCasters.count {
                scaledCasters[i].center *= Float(scale)
                scaledCasters[i].size *= Float(scale)
                scaledCasters[i].offset *= Float(scale)
                scaledCasters[i].radius *= Float(scale)
                scaledCasters[i].cornerRadius *= Float(scale)
            }
            shadowCasterBuffer = device.makeBuffer(bytes: scaledCasters, length: scaledCasters.count * MemoryLayout<ShadowCaster>.stride, options: [.storageModeShared])
        } else { shadowCasterBuffer = nil }
    }

    func draw(in view: MTKView) {
        #if DEBUG
        RenderPerformanceMonitor.shared.tickFrame()
        #endif
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let parent = parentView,
              let backgroundProvider = backgroundProvider else { return }
        
        updateBuffers(for: view)
        guard let shapeBuffer = shapeDataBuffer, let paramBuffer = paramDataBuffer else { return }
        
        guard let slot0Tex = backgroundProvider.texture(for: parent, shouldUpdate: shouldUpdateBackgroundSnapshot) else { return }
        
        let slot1Tex = parent.additionalTextures[1] ?? slot0Tex
        let slot2Tex = parent.additionalTextures[2] ?? slot0Tex
        let slot3Tex = parent.additionalTextures[3] ?? slot0Tex
        
        shouldUpdateBackgroundSnapshot = false
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        if let pipelineState = pipelineState {
            encoder.setRenderPipelineState(pipelineState)
            
            let maxLayerID = parent.shapes.map { $0.layerID }.max() ?? 0
            
            var uniforms = Uniforms(
                size: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
                shapeCount: Int32(shapeBuffer.length / MemoryLayout<Float>.size),
                paramCount: Int32(paramBuffer.length / MemoryLayout<Float>.size),
                shadowCasterCount: Int32(parent.shadowCasters.count),
                maxLayerIndex: maxLayerID,
                textureOffset: SIMD2<Float>(Float(parent.textureOffset.x), Float(parent.textureOffset.y)),
                uvScale: SIMD2<Float>(Float(parent.textureUvScale.x), Float(parent.textureUvScale.y))
            )
            
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
            encoder.setFragmentBuffer(shapeBuffer, offset: 0, index: 1)
            encoder.setFragmentBuffer(paramBuffer, offset: 0, index: 2)
            if let shadowBuffer = shadowCasterBuffer, shadowBuffer.length > 0 {
                encoder.setFragmentBuffer(shadowBuffer, offset: 0, index: 3)
            } else {
                encoder.setFragmentBuffer(paramBuffer, offset: 0, index: 3)
            }
            
            encoder.setFragmentTexture(slot0Tex, index: 0)
            encoder.setFragmentTexture(slot1Tex, index: 1)
            encoder.setFragmentTexture(slot2Tex, index: 2)
            encoder.setFragmentTexture(slot3Tex, index: 3)
            
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

#if DEBUG
public final class RenderPerformanceMonitor {
    public static let shared = RenderPerformanceMonitor()
    
    private var lastTime: CFAbsoluteTime = 0
    private var frameCount: Int = 0
    private var totalSnapshotTime: CFAbsoluteTime = 0
    private var snapshotCount: Int = 0
    
    public var isEnabled: Bool = false
    
    func logSnapshotDuration(_ duration: TimeInterval) {
        guard isEnabled else { return }
        totalSnapshotTime += duration
        snapshotCount += 1
        if duration > 0.016 {
            print("⚠️ SLOW SNAPSHOT: \(String(format: "%.2f", duration * 1000))ms")
        }
    }
    
    func tickFrame() {
        guard isEnabled else { return }
        let currentTime = CFAbsoluteTimeGetCurrent()
        frameCount += 1
        
        if currentTime - lastTime >= 1.0 {
            let avgSnapshot = snapshotCount > 0 ? (totalSnapshotTime / Double(snapshotCount)) * 1000 : 0
            print("📊 FPS: \(frameCount) | Avg Snapshot CPU Time: \(String(format: "%.2f", avgSnapshot))ms")
            
            frameCount = 0
            lastTime = currentTime
            totalSnapshotTime = 0
            snapshotCount = 0
        }
    }
}
#endif
