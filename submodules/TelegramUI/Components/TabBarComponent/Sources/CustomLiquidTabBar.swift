//  CustomLiquidTabBar.swift

import Foundation
import UIKit
import Display
import TelegramPresentationData
import ComponentFlow
import ComponentDisplayAdapters
import GlassBackgroundComponent
import MultilineTextComponent
import LottieComponent
import UIKitRuntimeUtils
import BundleIconComponent
import TextBadgeComponent

// MARK: - Configuration

final class LiquidConfig {
    static let shared = LiquidConfig()
    
    // MARK: Layout
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    
    var itemSpacing: CGFloat {
        if screenWidth <= 320 { return 16.0 }
        if screenWidth <= 375 { return 18.0 }
        return 20.0
    }
    
    var fixedItemSize: CGSize {
        if screenWidth <= 320 { return CGSize(width: 47.0, height: 52.0) }
        if screenWidth <= 375 { return CGSize(width: 49.0, height: 54.0) }
        return CGSize(width: 51.0, height: 56.0)
    }
    
    var horizontalPadding: CGFloat {
        if screenWidth <= 320 { return 17.0 }
        if screenWidth <= 375 { return 19.0 }
        return 21.0
    }
    
    var verticalPadding: CGFloat = 4.0
    
    // MARK: Physics & Animation
    var heightExpansion: CGFloat = 16.0
    var widthExpansion: CGFloat = 16.0
    
    var springTension: CGFloat = 300.0
    var springFriction: CGFloat = 20.0
    
    var tapSpringTension: CGFloat = 340.0
    var tapSpringFriction: CGFloat = 30.0
    
    var sizeSpringTension: CGFloat = 180.0
    var sizeSpringFriction: CGFloat = 12.0
    
    var deformationFactor: CGFloat = 0.0005
    var maxDeformation: CGFloat = 11.0
    
    var fluidPhysicsEnabled: Bool = true
    var velocityStretchFactor: CGFloat = 0.04
    var velocitySquashFactor: CGFloat = 0.05
    var maxFluidDeformation: CGFloat = 4.0
    var maxFluidCompression: CGFloat = 15.0
    var shapeRestitutionTension: CGFloat = 200.0
    var shapeRestitutionFriction: CGFloat = 12.0
    
    var compressionHeightFactor: CGFloat = 0.35
    var stretchHeightFactor: CGFloat = 0.6
    
    // MARK: Interaction Scaling
    var interactionScale: CGFloat = 1.063
    var interactionAnimationDuration: TimeInterval = 0.6
    var interactionAnimationDamping: CGFloat = 1.0
    
    var barShiftEnabled: Bool = false
    var barShiftFactor: CGFloat = 0.02
    var maxBarShift: CGFloat = 1.3
    
    var renderDistanceThreshold: CGFloat = 0.5
    var renderScaleThreshold: CGFloat = 0.005
    
    // MARK: Indicator Base
    var indicatorStaticWidth: CGFloat = 84.0
    var indicatorStaticHeight: CGFloat = 56.0
    var indicatorStaticRadius: CGFloat = 10.0
    var indicatorStaticColor: UIColor? = nil
    var indicatorArrivalDistanceThreshold: CGFloat = 8.0
    
    // MARK: Top Lens (Mask & Glass)
    var topLensMagnification: CGFloat = 1.1
    var topLensMaskWidthMultiplier: CGFloat = 0.95
    var topLensMaskHeightMultiplier: CGFloat = 0.95
    
    var shadowColor: UIColor = .black
    var shadowOpacity: Float = 0.15
    var shadowOffset: CGSize = CGSize(width: 0, height: 4)
    var shadowRadius: CGFloat = 8.0
    
    var topLensRefractionEnabled: Bool = true
    var topLensRefraction: Float = 0.037
    var topLensThickness: Float = 45.0
    var topLensDome: Float = 4.4
    var topLensChromaticAberration: Float = 0.2
    
    var topLensLightingEnabled: Bool = true
    var topLensLightIntensity: Float = 0.8
    var topLensLightAngle: Float = 2.4
    var topLensAmbient: Float = 0.86
    
    var topLensColorEnabled: Bool = false
    var topLensCustomIndicatorColorLight: UIColor? = UIColor(white: 224.0 / 255.0, alpha: 1.0)
    var topLensCustomIndicatorColorDark: UIColor? = UIColor(white: 60.0 / 255.0, alpha: 1)
    
    var topLensBlurEnabled: Bool = false
    var topLensBlurRadius: Float = 0.0
    
    var topLensIndicatorPositionThreshold: CGFloat = 0.5
    var topLensIndicatorSizeThreshold: CGFloat = 0.3
    var topLensIndicatorTextureOffsetThreshold: CGFloat = 0.001
    var topLensIndicatorRenderSkipFrames: Int = 0
    var topLensIndicatorFinishDistanceThreshold: CGFloat = 1.0
    
    // MARK: Bottom Lens
    var isBottomLensEnabled: Bool = true
    var bottomLensColorEnabled: Bool = false
    var bottomLensColor: UIColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5)
    var bottomLensRefractionEnabled: Bool = true
    var bottomLensRefraction: Float = -0.03
    var bottomLensThickness: Float = 30.0
    var bottomLensDome: Float = 2.2
    var bottomLensChromaticAberration: Float = 0.0
    var bottomLensLightingEnabled: Bool = false
    var bottomLensLightIntensity: Float = 1.5
    var bottomLensLightAngle: Float = -0.5
    var bottomLensAmbient: Float = 0.5
    var bottomLensBlurEnabled: Bool = false
    var bottomLensBlurRadius: Float = 0.1
    
    // MARK: Bar Glass
    var barRefractionEnabled: Bool = true
    var barRefraction: Float = 0.013
    var barThickness: Float = 57.0
    var barLensDome: Float = 10
    var barChromaticAberration: Float = 0.0
    
    var barLightingEnabled: Bool = true
    var barLightIntensity: Float = 0.04
    var barLightAngle: Float = 0.785
    var barAmbient: Float = 0.8
    
    var barColorEnabled: Bool = true
    var customBarColorLight: UIColor? = UIColor(white: 1.0, alpha: 0.6)
    var customBarColorDark: UIColor? = UIColor(white: 0.1, alpha: 0.6)
    
    var barBlurEnabled: Bool = true
    var barBlurRadius: Float = 5.0
    
    var barShadowEnabled: Bool = true
    var barShadowColor: UIColor = .black
    var barShadowOpacity: Float = 0.11
    var barShadowRadius: CGFloat = 16.0
    var barShadowOffset: CGSize = CGSize(width: 0, height: 6)
    
    var barCaptureScale: CGFloat = UIScreen.main.scale * 0.5
    var barGlassAnimationFPS: Double = 60.0
    var backgroundCapturePadding: CGFloat = 50.0
    
    // MARK: Control
    var minLensDisplayDuration: TimeInterval = 0.3
    var lensSwitchAnimationDuration: TimeInterval = 0.1
    var animateTabSelection: Bool = false
    
    // MARK: Effects (Glow & Dispersion)
    var glowEnabled: Bool = true
    var glowColor: UIColor = UIColor(white: 1.0, alpha: 0.8)
    var glowMaxRadius: Float = 180.0
    var glowBaseIntensity: Float = 0.15
    var glowPhysicsSensitivity: Float = 0.0
    
    var dispersionEnabled: Bool = false
    var dispersionBase: Float = 3.1
    var dispersionMax: Float = 5.6
    var dispersionSensitivity: Float = 1.18
    
    var onConfigUpdate: (() -> Void)?
    
    // MARK: Methods
    
    func getBarColor(theme: PresentationTheme) -> UIColor {
        if theme.overallDarkAppearance, let custom = customBarColorDark { return custom }
        if !theme.overallDarkAppearance, let custom = customBarColorLight { return custom }
        return theme.chat.inputPanel.inputBackgroundColor.withMultipliedAlpha(0.85)
    }
    
    func getIndicatorColor(theme: PresentationTheme) -> UIColor {
        if theme.overallDarkAppearance, let custom = topLensCustomIndicatorColorDark { return custom }
        if !theme.overallDarkAppearance, let custom = topLensCustomIndicatorColorLight { return custom }
        return theme.list.itemPrimaryTextColor
    }
}

// MARK: - LiquidItemComponent

final class LiquidItemComponent: Component {
    let item: TabBarComponent.Item
    let theme: PresentationTheme
    
    init(item: TabBarComponent.Item, theme: PresentationTheme) {
        self.item = item
        self.theme = theme
    }
    
    static func ==(lhs: LiquidItemComponent, rhs: LiquidItemComponent) -> Bool {
        if lhs.item != rhs.item { return false }
        if lhs.theme !== rhs.theme { return false }
        return true
    }
    
    final class View: UIView {
        private let unselectedItem = ComponentView<Empty>()
        private let selectedItem = ComponentView<Empty>()
        
        private let selectedMaskLayer = CAShapeLayer()
        private let unselectedMaskLayer = CAShapeLayer()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        func getInnerView() -> ItemComponent.View? {
            return self.selectedItem.view as? ItemComponent.View
        }
        
        func playSelectionAnimation() {
            (self.selectedItem.view as? ItemComponent.View)?.playSelectionAnimation()
        }
        
        func update(component: LiquidItemComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let _ = self.unselectedItem.update(
                transition: transition,
                component: AnyComponent(ItemComponent(item: component.item, theme: component.theme, isSelected: false)),
                environment: {},
                containerSize: availableSize
            )
            let _ = self.selectedItem.update(
                transition: transition,
                component: AnyComponent(ItemComponent(item: component.item, theme: component.theme, isSelected: true)),
                environment: {},
                containerSize: availableSize
            )
            
            if let unselectedView = self.unselectedItem.view {
                if unselectedView.superview == nil {
                    self.addSubview(unselectedView)
                    unselectedView.layer.mask = self.unselectedMaskLayer
                }
                transition.setFrame(view: unselectedView, frame: CGRect(origin: .zero, size: availableSize))
            }
            if let selectedView = self.selectedItem.view {
                if selectedView.superview == nil {
                    self.addSubview(selectedView)
                    selectedView.layer.mask = self.selectedMaskLayer
                }
                transition.setFrame(view: selectedView, frame: CGRect(origin: .zero, size: availableSize))
            }
            
            return availableSize
        }
        
        func updateMaskAndTransform(indicatorFrame: CGRect, isDynamic: Bool, isSelectedItem: Bool, isFinishingInteraction: Bool) {
            let hasOverlap = isDynamic && !indicatorFrame.isNull && indicatorFrame.intersects(self.bounds)
            
            if isDynamic && !isFinishingInteraction {
                self.unselectedItem.view?.layer.mask = self.unselectedMaskLayer
                
                if isSelectedItem {
                    self.selectedItem.view?.alpha = 0.0
                    self.unselectedItem.view?.alpha = 1.0
                }
                
                if hasOverlap {
                    let lensPath = UIBezierPath(roundedRect: indicatorFrame, cornerRadius: indicatorFrame.height / 2.0)
                    let holePath = CGMutablePath()
                    holePath.addRect(self.bounds)
                    holePath.addPath(lensPath.cgPath)
                    
                    self.unselectedMaskLayer.path = holePath
                    self.unselectedMaskLayer.fillRule = .evenOdd
                } else {
                    self.unselectedMaskLayer.path = UIBezierPath(rect: self.bounds).cgPath
                }
            } else {
                self.selectedItem.view?.layer.mask = nil
                self.unselectedItem.view?.layer.mask = nil
                
                if isSelectedItem {
                    self.selectedItem.view?.alpha = 1.0
                    self.unselectedItem.view?.alpha = 0.0
                } else {
                    self.selectedItem.view?.alpha = 0.0
                    self.unselectedItem.view?.alpha = 1.0
                }
            }
        }
        
        func renderSelectedState(in context: CGContext, scale: CGFloat) {
            guard let selectedView = self.selectedItem.view else { return }
            
            let wasHidden = selectedView.isHidden
            let originalMask = selectedView.layer.mask
            
            selectedView.isHidden = false
            selectedView.layer.mask = nil
            
            context.saveGState()
            context.translateBy(x: self.frame.origin.x, y: self.frame.origin.y)
            context.translateBy(x: self.bounds.midX, y: self.bounds.midY)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -self.bounds.midX, y: -self.bounds.midY)
            
            if let subview = self.selectedItem.view {
                subview.layer.render(in: context)
            }
            
            context.restoreGState()
            selectedView.layer.mask = originalMask
            selectedView.isHidden = wasHidden
        }
    }
    
    func makeView() -> View { View(frame: CGRect()) }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(
            component: self,
            availableSize: availableSize,
            state: state,
            environment: environment,
            transition: transition
        )
    }
}

// MARK: - CustomLiquidTabBarView

final class CustomLiquidTabBarView: UIView, TabBarImplementation, UIGestureRecognizerDelegate {
    
    private class TabBarGlassView: LiquidGlassUIView {
        weak var itemsContainer: UIView?
        weak var shadowRef: UIView?
        
        override var isHidden: Bool {
            didSet {
                itemsContainer?.alpha = isHidden ? 0.0 : 1.0
                shadowRef?.alpha = isHidden ? 0.0 : 1.0
            }
        }
    }
    
    private let scalableContainer = UIView()
    private let contentContainerView = UIView()
    private let backgroundView = TabBarGlassView()
    private let shadowView = UIView()
    
    private var liquidIndicator: LiquidIndicator?
    private var panGesture: UIPanGestureRecognizer?
    
    private var itemViews: [AnyHashable: ComponentView<Empty>] = [:]
    private var component: TabBarComponent?
    
    private var forceComponentUpdate: (() -> Void)?
    
    private(set) var isInteracting: Bool = false
    private(set) var isAnimatingTap: Bool = false
    
    private var interactionSessionId: UInt64 = 0
    private var tapAnimationSessionId: UInt64 = 0
    private var finishingAnimationTargetId: AnyHashable?
    
    private var containerScale: CGFloat = 1.0
    private var containerScaleVelocity: CGFloat = 0.0
    private var targetContainerScale: CGFloat = 1.0
    
    private var manualBarShift: CGFloat = 0.0
    
    private var backgroundUpdateLink: CADisplayLink?
    private var lastBackgroundUpdateTime: TimeInterval = 0.0
    private var lastRenderExecutionTime: TimeInterval = 0.0
    
    private var lastRenderedTranslationX: CGFloat = 0.0
    private var lastRenderedScale: CGFloat = 1.0
    
    private var itemFrames: [AnyHashable: CGRect] = [:]
    private var dragMinX: CGFloat = 0.0
    private var dragMaxX: CGFloat = 0.0
    private var fixedY: CGFloat = 0.0
    
    private var lensActivationTimestamp: TimeInterval = 0.0
    private var snapshotComponentViews: [AnyHashable: ComponentView<Empty>] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        
        self.scalableContainer.clipsToBounds = false
        self.addSubview(self.scalableContainer)
        
        self.shadowView.isUserInteractionEnabled = false
        self.shadowView.backgroundColor = .clear
        self.scalableContainer.addSubview(self.shadowView)
        
        self.backgroundView.renderMode = .automatic
        self.backgroundView.backgroundProvider?.captureScale = LiquidConfig.shared.barCaptureScale
        self.backgroundView.isUserInteractionEnabled = false
        self.scalableContainer.addSubview(self.backgroundView)
        
        self.backgroundView.canUpdateSnapshotCallback = { [weak self] in
            guard let self = self else { return false }
            if self.backgroundView.isHidden || self.isInteracting { return false }
            return true
        }
        
        self.scalableContainer.addSubview(self.contentContainerView)
        
        self.backgroundView.itemsContainer = self.contentContainerView
        self.backgroundView.shadowRef = self.shadowView
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:))))
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        self.panGesture = panGesture
        
        let existingCallback = LiquidConfig.shared.onConfigUpdate
        LiquidConfig.shared.onConfigUpdate = { [weak self] in
            existingCallback?()
            DispatchQueue.main.async { self?.forceComponentUpdate?() }
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            self.backgroundView.render()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.backgroundView.forceRender()
            }
        }
    }
    
    // MARK: - Glass Setup
    
    private func setupBarGlass(theme: PresentationTheme) {
        let cfg = LiquidConfig.shared
        
        var barParams = LiquidGlassParameters()
        barParams.isGlassColorEnabled = cfg.barColorEnabled
        barParams.glassColor = cfg.getBarColor(theme: theme)
        barParams.isLightingEnabled = cfg.barLightingEnabled
        barParams.lightAngle = cfg.barLightAngle
        barParams.lightIntensity = cfg.barLightIntensity
        barParams.ambientStrength = cfg.barAmbient
        barParams.isRefractionEnabled = cfg.barRefractionEnabled
        barParams.thickness = cfg.barThickness
        barParams.refractiveIndex = cfg.barRefraction
        barParams.chromaticAberration = cfg.barChromaticAberration
        barParams.lensDome = cfg.barLensDome
        barParams.isBlurEnabled = cfg.barBlurEnabled
        barParams.blurRadius = cfg.barBlurRadius
        barParams.blend = 0.0
        barParams.opticalPassThrough = 1.0
        
        var lensParams = LiquidGlassParameters()
        lensParams.isGlassColorEnabled = cfg.bottomLensColorEnabled
        lensParams.glassColor = cfg.bottomLensColor
        lensParams.isLightingEnabled = cfg.bottomLensLightingEnabled
        lensParams.lightAngle = cfg.bottomLensLightAngle
        lensParams.lightIntensity = cfg.bottomLensLightIntensity
        lensParams.ambientStrength = cfg.bottomLensAmbient
        lensParams.isRefractionEnabled = cfg.bottomLensRefractionEnabled
        lensParams.thickness = cfg.bottomLensThickness
        lensParams.refractiveIndex = cfg.bottomLensRefraction
        lensParams.chromaticAberration = cfg.bottomLensChromaticAberration
        lensParams.lensDome = cfg.bottomLensDome
        lensParams.isBlurEnabled = cfg.bottomLensBlurEnabled
        lensParams.blurRadius = cfg.bottomLensBlurRadius
        lensParams.blend = 80.0
        barParams.opticalPassThrough = 0.0
        
        self.backgroundView.layerParameters = [barParams, lensParams]
        self.backgroundView.render()
        self.updateShadow()
    }
    
    private func updateShadow() {
        let cfg = LiquidConfig.shared
        if cfg.barShadowEnabled {
            self.shadowView.layer.shadowColor = cfg.barShadowColor.cgColor
            self.shadowView.layer.shadowOpacity = cfg.barShadowOpacity
            self.shadowView.layer.shadowRadius = cfg.barShadowRadius
            self.shadowView.layer.shadowOffset = cfg.barShadowOffset
            
            let shadowPath = UIBezierPath(roundedRect: self.shadowView.bounds, cornerRadius: self.shadowView.bounds.height / 2.0).cgPath
            self.shadowView.layer.shadowPath = shadowPath
        } else {
            self.shadowView.layer.shadowOpacity = 0.0
        }
    }
    
    // MARK: - Animation Loop & Transformations
    
    private func setExpanded(_ expanded: Bool) {
        let cfg = LiquidConfig.shared
        self.targetContainerScale = expanded ? cfg.interactionScale : 1.0
        
        if abs(self.containerScale - self.targetContainerScale) > 0.001 || self.isInteracting {
            self.startBackgroundUpdateLoop()
        }
    }
    
    private func forceSetExpanded(_ expanded: Bool, animated: Bool) {
        let cfg = LiquidConfig.shared
        self.targetContainerScale = expanded ? cfg.interactionScale : 1.0
        
        if !animated {
            self.containerScale = self.targetContainerScale
            self.containerScaleVelocity = 0.0
            self.manualBarShift = 0.0
            self.updateContainerTransform(scale: self.containerScale, translationX: 0.0)
            self.stopBackgroundUpdateLoop()
        } else {
            self.startBackgroundUpdateLoop()
        }
    }
    
    private func renderBackground(forceSnapshot: Bool = false) {
        let currentTransform = self.scalableContainer.transform
        let currentTx = currentTransform.tx
        let currentScale = currentTransform.a
        let cfg = LiquidConfig.shared
        
        if !forceSnapshot {
            let txDiff = abs(currentTx - self.lastRenderedTranslationX)
            let scaleDiff = abs(currentScale - self.lastRenderedScale)
            if txDiff < cfg.renderDistanceThreshold && scaleDiff < cfg.renderScaleThreshold { return }
        }
        
        self.lastRenderedTranslationX = currentTx
        self.lastRenderedScale = currentScale
        
        let shouldSnapshot = forceSnapshot || (!self.isInteracting && !self.isAnimatingTap)
        self.backgroundView.render(updateSnapshot: shouldSnapshot)
    }
    
    private func updateContainerTransform(scale: CGFloat, translationX: CGFloat) {
        let transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: translationX, y: 0)
        self.scalableContainer.transform = transform
    }
    
    private func startBackgroundUpdateLoop() {
        if self.backgroundUpdateLink == nil {
            let displayLink = CADisplayLink(target: self, selector: #selector(backgroundUpdateTick))
            displayLink.add(to: .main, forMode: .common)
            self.backgroundUpdateLink = displayLink
            
            let now = CACurrentMediaTime()
            self.lastBackgroundUpdateTime = now
            self.lastRenderExecutionTime = 0.0
        }
    }
    
    private func stopBackgroundUpdateLoop() {
        self.backgroundUpdateLink?.invalidate()
        self.backgroundUpdateLink = nil
    }
    
    @objc private func backgroundUpdateTick() {
        let currentTime = CACurrentMediaTime()
        var dt = currentTime - self.lastBackgroundUpdateTime
        self.lastBackgroundUpdateTime = currentTime
        if dt > 0.05 { dt = 0.05 }
        
        let cfg = LiquidConfig.shared
        
        // 1. Scale Physics
        let force = (self.targetContainerScale - self.containerScale) * cfg.springTension
        let friction = self.containerScaleVelocity * cfg.springFriction
        let acceleration = force - friction
        
        self.containerScaleVelocity += acceleration * CGFloat(dt)
        self.containerScale += self.containerScaleVelocity * CGFloat(dt)
        
        // 2. Shift Physics
        var currentShift = self.manualBarShift
        if !self.isInteracting {
            let shiftDiff = 0.0 - self.manualBarShift
            self.manualBarShift += shiftDiff * 10.0 * CGFloat(dt)
            if abs(self.manualBarShift) < 0.1 { self.manualBarShift = 0 }
            currentShift = self.manualBarShift
        }
        
        self.updateContainerTransform(scale: self.containerScale, translationX: currentShift)
        
        // 3. UV Compensation
        if self.isInteracting || self.isAnimatingTap || abs(self.containerScale - 1.0) > 0.001 || abs(currentShift) > 0.1 {
            let uvScaleFactor = self.containerScale
            let capturePadding = LiquidConfig.shared.backgroundCapturePadding
            let totalTextureWidth = self.scalableContainer.bounds.width + (capturePadding * 2.0)
            
            let normalizedShiftX = -(currentShift / totalTextureWidth)
            let centerCorrectionX = 0.5 - (0.5 * uvScaleFactor)
            let centerCorrectionY = 0.5 - (0.5 * uvScaleFactor)
            
            let finalOffsetX = normalizedShiftX + centerCorrectionX
            let finalOffsetY = centerCorrectionY
            
            self.backgroundView.textureUvScale = CGPoint(x: uvScaleFactor, y: uvScaleFactor)
            self.backgroundView.textureOffset = CGPoint(x: finalOffsetX, y: finalOffsetY)
        } else {
            self.backgroundView.textureUvScale = CGPoint(x: 1.0, y: 1.0)
            self.backgroundView.textureOffset = .zero
        }
        
        // 4. Render
        let targetFrameDuration = cfg.barGlassAnimationFPS > 0 ? (1.0 / cfg.barGlassAnimationFPS) : 0.0
        let timeSinceLastRender = currentTime - self.lastRenderExecutionTime
        
        if timeSinceLastRender >= targetFrameDuration || self.lastRenderExecutionTime == 0 {
            self.renderBackground(forceSnapshot: false)
            self.lastRenderExecutionTime = currentTime
        }
        
        // 5. Completion Check
        let isScaleSettled = abs(self.containerScale - self.targetContainerScale) < 0.0005 && abs(self.containerScaleVelocity) < 0.01
        let isShiftSettled = abs(currentShift) < 0.1
        
        if isScaleSettled && isShiftSettled && !self.isInteracting && !self.isAnimatingTap {
            self.containerScale = self.targetContainerScale
            self.updateContainerTransform(scale: self.containerScale, translationX: 0)
            
            self.backgroundView.textureUvScale = CGPoint(x: 1.0, y: 1.0)
            self.backgroundView.textureOffset = .zero
            
            self.stopBackgroundUpdateLoop()
            self.renderBackground(forceSnapshot: true)
        }
    }
    
    // MARK: - Component Update
    
    func update(component: TabBarComponent, availableSize: CGSize, state: EmptyComponentState, transition: ComponentTransition) -> CGSize {
        let previousComponent = self.component
        self.component = component
        self.itemFrames.removeAll()
        
        self.forceComponentUpdate = {
            state.updated(transition: .immediate, isLocal: true)
        }
        
        self.setupBarGlass(theme: component.theme)

        if previousComponent?.theme !== component.theme || previousComponent?.selectedId != component.selectedId {
            self.backgroundView.wakeUp(duration: 0.6)

            DispatchQueue.main.async { [weak self] in
                self?.backgroundView.render(updateSnapshot: true)
            }
        }
        
        let cfg = LiquidConfig.shared
        let itemCount = component.items.count
        guard itemCount > 0 else { return .zero }
        
        let itemSize = cfg.fixedItemSize
        let totalItemsWidth = itemSize.width * CGFloat(itemCount)
        let totalSpacingWidth = cfg.itemSpacing * CGFloat(max(0, itemCount - 1))
        let contentWidth = totalItemsWidth + totalSpacingWidth
        
        let finalBarWidth = contentWidth + cfg.horizontalPadding * 2
        let finalHeight = itemSize.height + cfg.verticalPadding * 2
        let finalSize = CGSize(width: finalBarWidth, height: finalHeight)
        
        if !self.isInteracting && !self.isAnimatingTap && self.backgroundUpdateLink == nil {
            let containerBounds = CGRect(origin: .zero, size: finalSize)
            let containerCenter = CGPoint(x: availableSize.width / 2.0, y: finalSize.height / 2.0)
            
            if self.scalableContainer.bounds != containerBounds {
                self.scalableContainer.bounds = containerBounds
            }
            if self.scalableContainer.center != containerCenter {
                self.scalableContainer.center = containerCenter
            }
        }
        
        self.contentContainerView.frame = self.scalableContainer.bounds
        let capturePadding = LiquidConfig.shared.backgroundCapturePadding
        let expandedFrame = self.scalableContainer.bounds.insetBy(dx: -capturePadding, dy: -capturePadding)
        self.backgroundView.frame = expandedFrame
        self.shadowView.frame = self.scalableContainer.bounds
        
        let startX = (finalSize.width - contentWidth) / 2.0
        var currentX = startX
        
        var validIds: [AnyHashable] = []
        for item in component.items {
            validIds.append(item.id)
            
            let itemFrame = CGRect(origin: CGPoint(x: currentX, y: cfg.verticalPadding), size: itemSize)
            self.itemFrames[item.id] = itemFrame
            
            let itemView = self.itemViews[item.id] ?? ComponentView()
            self.itemViews[item.id] = itemView
            
            let _ = itemView.update(transition: transition, component: AnyComponent(LiquidItemComponent(item: item, theme: component.theme)), environment: {}, containerSize: itemSize)
            
            if let view = itemView.view as? LiquidItemComponent.View {
                if view.superview == nil {
                    view.isUserInteractionEnabled = false
                    self.contentContainerView.addSubview(view)
                }
                transition.setFrame(view: view, frame: itemFrame)
                
                if !isInteracting && !isAnimatingTap {
                    let isSelected = component.selectedId == item.id
                    var staticMaskFrame: CGRect = .null
                    if isSelected {
                        let staticW = cfg.indicatorStaticWidth
                        let staticH = cfg.indicatorStaticHeight
                        staticMaskFrame = CGRect(
                            x: (itemSize.width - staticW) / 2.0,
                            y: (itemSize.height - staticH) / 2.0,
                            width: staticW,
                            height: staticH
                        )
                    }
                    view.updateMaskAndTransform(
                        indicatorFrame: staticMaskFrame,
                        isDynamic: false,
                        isSelectedItem: isSelected,
                        isFinishingInteraction: false
                    )
                }
                
                if LiquidConfig.shared.animateTabSelection {
                    if previousComponent?.selectedId != item.id, component.selectedId == item.id {
                        view.playSelectionAnimation()
                    }
                }
            }
            currentX += itemSize.width + cfg.itemSpacing
        }
        
        var removeIds: [AnyHashable] = []
        for id in self.itemViews.keys {
            if !validIds.contains(id) {
                removeIds.append(id)
                self.itemViews[id]?.view?.removeFromSuperview()
            }
        }
        for id in removeIds { self.itemViews.removeValue(forKey: id) }
        
        self.ensureLiquidIndicatorExists()
        if let liquidIndicator = self.liquidIndicator, let selectedId = component.selectedId, let rect = self.itemFrames[selectedId] {
            let indicatorColor = cfg.getIndicatorColor(theme: component.theme)
            liquidIndicator.updateStaticColor(indicatorColor)
            liquidIndicator.updateTheme(component.theme)
            self.sendLiquidIndicatorToBack()
            
            if !self.isInteracting && !self.isAnimatingTap && !liquidIndicator.isAnimating() {
                liquidIndicator.configure(rect: rect)
                liquidIndicator.isHidden = false
                self.sendLiquidIndicatorToBack()
            }
        } else {
            self.liquidIndicator?.isHidden = true
        }
        
        self.updateShadow()
        
        if self.liquidIndicator?.mode != .dynamic {
            if let selectedId = component.selectedId, let rect = self.itemFrames[selectedId] {
                let cfg = LiquidConfig.shared
                let radius = cfg.indicatorStaticRadius > 0 ? cfg.indicatorStaticRadius : (rect.height / 2.0)
                self.updateBackgroundShapes(indicatorFrame: rect, indicatorCornerRadius: radius)
            } else {
                self.updateBackgroundShapes(indicatorFrame: nil, indicatorCornerRadius: nil)
            }
        }
        
        self.backgroundView.render()
        
        return CGSize(width: availableSize.width, height: finalHeight)
    }
    
    // MARK: - Logic Sync
    
    func syncItemsWithIndicator(indicatorFrame: CGRect, isDynamic: Bool, isFinishing: Bool) {
        guard let component = self.component else { return }
        
        let influenceRadius = indicatorFrame.width * 1.5
        
        for (itemId, itemView) in self.itemViews {
            guard let view = itemView.view as? LiquidItemComponent.View else { continue }
            
            let itemCenter = view.center
            let distance = hypot(indicatorFrame.midX - itemCenter.x, indicatorFrame.midY - itemCenter.y)
            
            let isDataSelected = component.selectedId == itemId
            let isSelected = isDataSelected || (isFinishing && self.finishingAnimationTargetId == itemId)
            
            if isDynamic && distance > influenceRadius && !isSelected {
                view.updateMaskAndTransform(
                    indicatorFrame: .null,
                    isDynamic: false,
                    isSelectedItem: false,
                    isFinishingInteraction: isFinishing
                )
                continue
            }
            
            let indicatorFrameInItem = view.convert(indicatorFrame, from: self.contentContainerView)
            
            view.updateMaskAndTransform(
                indicatorFrame: indicatorFrameInItem,
                isDynamic: isDynamic,
                isSelectedItem: isSelected,
                isFinishingInteraction: isFinishing
            )
        }
    }
    
    private func updateBackgroundShapes(indicatorFrame: CGRect?, indicatorCornerRadius: CGFloat?, effects: LiquidIndicator.DynamicEffectsState? = nil) {
        let bounds = self.backgroundView.bounds
        if bounds.width < 1 || bounds.height < 1 { return }
        
        let padding = LiquidConfig.shared.backgroundCapturePadding
        let barWidth = Float(bounds.width - (padding * 2.0))
        let barHeight = Float(bounds.height - (padding * 2.0))
        
        let barCenter = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        let barSize = CGSize(width: CGFloat(barWidth), height: CGFloat(barHeight))
        let barCornerRadius = barSize.height / 2.0
        
        let barShape = ShapeData(
            type: .squircle,
            x: Float(barCenter.x),
            y: Float(barCenter.y),
            width: Float(barSize.width),
            height: Float(barSize.height),
            cornerRadius: Float(barCornerRadius),
            layerID: 0
        )
        
        var shapes = [barShape]
        var shadowCasters: [ShadowCaster] = []
        let cfg = LiquidConfig.shared
        
        if cfg.barShadowEnabled {
            let barCaster = ShadowCaster(
                color: cfg.barShadowColor,
                center: barCenter,
                size: barSize,
                offset: cfg.barShadowOffset,
                radius: cfg.barShadowRadius,
                cornerRadius: barCornerRadius
            )
            var casterWithOpacity = barCaster
            casterWithOpacity.color.w = Float(cfg.barShadowOpacity)
            shadowCasters.append(casterWithOpacity)
        }
        
        if let rect = indicatorFrame, let radius = indicatorCornerRadius, !rect.isNull && !rect.isEmpty && radius > 0 {
            let correctedCenter = CGPoint(x: rect.midX + padding, y: rect.midY + padding)
            
            if cfg.isBottomLensEnabled && self.liquidIndicator?.mode == .dynamic {
                let lensShape = ShapeData(
                    type: .squircle,
                    x: Float(correctedCenter.x),
                    y: Float(correctedCenter.y),
                    width: Float(rect.width),
                    height: Float(rect.height),
                    cornerRadius: Float(radius),
                    layerID: 1
                )
                shapes.append(lensShape)
            }
            
            let indicatorCaster = ShadowCaster(
                color: cfg.shadowColor,
                center: correctedCenter,
                size: rect.size,
                offset: cfg.shadowOffset,
                radius: cfg.shadowRadius,
                cornerRadius: radius
            )
            var casterWithOpacity = indicatorCaster
            casterWithOpacity.color.w = Float(cfg.shadowOpacity)
            shadowCasters.append(casterWithOpacity)
        }
        
        let isDarkMode = self.component?.theme.overallDarkAppearance ?? false
        var barParams = self.backgroundView.layerParameters.first ?? LiquidGlassParameters()
        
        if let rect = indicatorFrame, let fx = effects, isDarkMode {
            barParams.glowEnabled = true
            let padding = LiquidConfig.shared.backgroundCapturePadding
            let pointCenterX = rect.midX + padding
            let pointCenterY = rect.midY + padding
            
            barParams.glowCenter = CGPoint(x: pointCenterX, y: pointCenterY)
            barParams.glowRadius = fx.glowRadius
            barParams.glowIntensity = fx.glowIntensity
            barParams.glowColor = cfg.glowColor
        } else {
            barParams.glowEnabled = false
        }
        barParams.textureIndex = 0
        
        var lensParams = self.backgroundView.layerParameters.count > 1 ? self.backgroundView.layerParameters[1] : LiquidGlassParameters()
        
        lensParams.isGlassColorEnabled = barParams.isGlassColorEnabled
        lensParams.glassColor = barParams.glassColor
        lensParams.isBlurEnabled = barParams.isBlurEnabled
        lensParams.blurRadius = barParams.blurRadius
        lensParams.textureIndex = 0
        
        if let fx = effects {
            lensParams.dispersionStrength = fx.dispersionStrength
        } else {
            lensParams.dispersionStrength = 0.0
        }
        
        self.backgroundView.layerParameters = [barParams, lensParams]
        self.backgroundView.shapes = shapes
        self.backgroundView.shadowCasters = shadowCasters
        
        if self.backgroundView.renderMode == .manual {
            self.backgroundView.render()
        }
    }
    
    // MARK: - Interactions
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.panGesture {
            let velocity = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: self)
            return abs(velocity.x) > abs(velocity.y)
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    private func generateHighResSnapshot() -> UIImage? {
        guard let component = self.component else { return nil }
        
        let cfg = LiquidConfig.shared
        let captureScale = UIScreen.main.scale * cfg.topLensMagnification
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = captureScale
        format.opaque = false
        
        let result = UIGraphicsImageRenderer(
            bounds: self.contentContainerView.bounds,
            format: format
        ).image { rendererContext in
            let context = rendererContext.cgContext
            
            for item in component.items {
                guard let itemFrame = self.itemFrames[item.id] else { continue }
                
                let snapshotComponentView: ComponentView<Empty>
                if let cached = self.snapshotComponentViews[item.id] {
                    snapshotComponentView = cached
                } else {
                    snapshotComponentView = ComponentView<Empty>()
                    self.snapshotComponentViews[item.id] = snapshotComponentView
                }
                
                let selectedStateComponent = LiquidItemComponent(
                    item: item,
                    theme: component.theme
                )
                let _ = snapshotComponentView.update(
                    transition: .immediate,
                    component: AnyComponent(selectedStateComponent),
                    environment: {},
                    containerSize: itemFrame.size
                )
                
                guard let liquidItemView = snapshotComponentView.view as? LiquidItemComponent.View else { continue }
                
                let needsTemporaryAdd = liquidItemView.superview == nil
                let tempContainer = UIView(frame: itemFrame)
                
                if needsTemporaryAdd {
                    tempContainer.addSubview(liquidItemView)
                    liquidItemView.frame = tempContainer.bounds
                }
                
                liquidItemView.layoutIfNeeded()
                
                guard let selectedItemView = liquidItemView.getInnerView() else {
                    if needsTemporaryAdd {
                        liquidItemView.removeFromSuperview()
                    }
                    continue
                }
                
                let wasHidden = selectedItemView.isHidden
                let wasMasked = selectedItemView.layer.mask
                let wasAlpha = selectedItemView.alpha
                
                selectedItemView.isHidden = false
                selectedItemView.layer.mask = nil
                selectedItemView.alpha = 1.0
                
                context.saveGState()
                
                context.translateBy(x: itemFrame.origin.x, y: itemFrame.origin.y)
                
                context.translateBy(x: itemFrame.width / 2, y: itemFrame.height / 2)
                context.scaleBy(x: cfg.topLensMagnification, y: cfg.topLensMagnification)
                context.translateBy(x: -itemFrame.width / 2, y: -itemFrame.height / 2)
                
                selectedItemView.layer.render(in: context)
                
                context.restoreGState()
                
                selectedItemView.isHidden = wasHidden
                selectedItemView.layer.mask = wasMasked
                selectedItemView.alpha = wasAlpha
                
                if needsTemporaryAdd {
                    liquidItemView.removeFromSuperview()
                }
            }
        }
        
        return result
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let component = self.component else { return }
        
        let pointInContent = recognizer.location(in: self.contentContainerView)
        let rawPoint = recognizer.location(in: self)
        let cfg = LiquidConfig.shared
        
        let calculateShift = { [weak self] () -> CGFloat in
            guard let self = self, cfg.barShiftEnabled else { return 0.0 }
            let centerX = self.bounds.width / 2.0
            let distFromCenter = rawPoint.x - centerX
            var shift = distFromCenter * cfg.barShiftFactor
            shift = max(-cfg.maxBarShift, min(cfg.maxBarShift, shift))
            return shift
        }
        
        switch recognizer.state {
        case .began:
            self.interactionSessionId &+= 1
            
            let needsTransformReset = abs(self.manualBarShift) > 0.1 || abs(self.containerScale - 1.0) > 0.001
            if needsTransformReset {
                
                self.stopBackgroundUpdateLoop()
                
                self.containerScale = 1.0
                self.targetContainerScale = 1.0
                self.containerScaleVelocity = 0.0
                self.manualBarShift = 0.0
                self.updateContainerTransform(scale: 1.0, translationX: 0.0)
                
                CATransaction.flush()
            }
            
            self.renderBackground(forceSnapshot: true)
            self.backgroundView.wakeUp(duration: 0.1)
            self.isAnimatingTap = false
            self.isInteracting = true
            
            self.setExpanded(true)
            self.manualBarShift = calculateShift()
            
            if let firstId = component.items.first?.id,
               let lastId = component.items.last?.id,
               let firstRect = self.itemFrames[firstId],
               let lastRect = self.itemFrames[lastId] {
                self.dragMinX = firstRect.midX
                self.dragMaxX = lastRect.midX
            }
            
            guard let liquidIndicator = self.liquidIndicator else { return }
            if liquidIndicator.isHidden || liquidIndicator.alpha == 0 {
                liquidIndicator.forceReset()
            }
            
            if let snapshot = self.generateHighResSnapshot() {
                liquidIndicator.setContentSnapshot(snapshot)
            }
            self.contentContainerView.bringSubviewToFront(liquidIndicator)
            
            self.lensActivationTimestamp = CACurrentMediaTime()
            liquidIndicator.setMode(.dynamic, animated: true)
            
            if let selectedId = component.selectedId, let rect = self.itemFrames[selectedId] {
                self.fixedY = rect.midY
            } else {
                self.fixedY = pointInContent.y
            }
            
            let startPhysicsPoint: CGPoint
            if !liquidIndicator.isHidden && liquidIndicator.alpha > 0.01 {
                startPhysicsPoint = liquidIndicator.layer.presentation()?.position ?? liquidIndicator.center
            } else if let selectedId = component.selectedId, let rect = self.itemFrames[selectedId] {
                startPhysicsPoint = CGPoint(x: rect.midX, y: rect.midY)
            } else {
                startPhysicsPoint = pointInContent
            }
            
            liquidIndicator.startInteraction(at: startPhysicsPoint, type: .gesture)
            liquidIndicator.updateInteraction(at: CGPoint(x: pointInContent.x, y: self.fixedY))
            
        case .changed:
            self.manualBarShift = calculateShift()
            guard let liquidIndicator = self.liquidIndicator else { return }
            liquidIndicator.updateInteraction(at: CGPoint(x: max(self.dragMinX, min(self.dragMaxX, pointInContent.x)), y: self.fixedY))
            
        case .ended, .cancelled:
            let sessionId = self.interactionSessionId
            self.isInteracting = false
            self.setExpanded(false)
            
            guard let liquidIndicator = self.liquidIndicator else { return }
            
            var closestItem: (AnyHashable, CGRect)?
            var minDistance: CGFloat = .greatestFiniteMagnitude
            
            for (id, rect) in self.itemFrames {
                let distance = abs(pointInContent.x - rect.midX)
                if distance < minDistance {
                    minDistance = distance
                    closestItem = (id, rect)
                }
            }
            
            if let (id, rect) = closestItem {
                self.finishingAnimationTargetId = id
                if let item = component.items.first(where: { $0.id == id }), component.selectedId != id {
                    item.action(false)
                }
                
                liquidIndicator.endInteraction(targetCenter: CGPoint(x: rect.midX, y: self.fixedY)) { [weak self] in
                    guard let self, sessionId == self.interactionSessionId else { return }
                    if !self.isInteracting && !self.isAnimatingTap {
                        liquidIndicator.clearContentSnapshot()
                        self.sendLiquidIndicatorToBack()
                    }
                }
            }
        default: break
        }
    }
    
    public func beginTapAnimation(for itemId: AnyHashable) {
        guard let targetRect = self.itemFrames[itemId] else { return }
        if self.isAnimatingTap || self.isInteracting { return }
        
        self.tapAnimationSessionId &+= 1
        self.isAnimatingTap = true
        self.forceSetExpanded(true, animated: true)
        
        guard let liquidIndicator = self.liquidIndicator else { return }
        liquidIndicator.forceReset()
        
        if let snapshot = self.generateHighResSnapshot() {
            liquidIndicator.setContentSnapshot(snapshot)
        }
        
        self.contentContainerView.bringSubviewToFront(liquidIndicator)
        self.lensActivationTimestamp = CACurrentMediaTime()
        liquidIndicator.setMode(.dynamic, animated: true)
        
        liquidIndicator.startInteraction(at: liquidIndicator.center, type: .tap)
        liquidIndicator.updateInteraction(at: targetRect.center)
    }
    
    public func cancelTapAnimation() {
        if !self.isAnimatingTap { return }
        
        self.tapAnimationSessionId &+= 1
        self.isAnimatingTap = false
        self.forceSetExpanded(false, animated: true)
        
        guard let liquidIndicator = self.liquidIndicator,
              let component = self.component,
              let selectedId = component.selectedId,
              let targetRect = self.itemFrames[selectedId] else {
            self.liquidIndicator?.isHidden = true
            return
        }
        
        self.finishingAnimationTargetId = selectedId 
        
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - self.lensActivationTimestamp
        let minDuration = LiquidConfig.shared.minLensDisplayDuration
        let remainingTime = max(0.0, minDuration - elapsed)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) { [weak self, weak liquidIndicator] in
            guard let self = self, let liquidIndicator = liquidIndicator else { return }
            if self.isInteracting || self.isAnimatingTap { return }
            liquidIndicator.setMode(.static, animated: true)
        }
        
        liquidIndicator.endInteraction(targetCenter: targetRect.center) { [weak self] in
            guard let self = self else { return }
            if !self.isInteracting && !self.isAnimatingTap {
                liquidIndicator.clearContentSnapshot()
                self.sendLiquidIndicatorToBack()
            }
        }
    }
    
    @objc private func onTapGesture(_ recognizer: UITapGestureRecognizer) {
        guard let component = self.component, case .ended = recognizer.state else { return }
        let point = recognizer.location(in: self)
        
        guard let hitId = self.hitTestItem(at: point) else {
            self.cancelTapAnimation()
            return
        }
        
        guard let item = component.items.first(where: { $0.id == hitId }) else { return }
        
        if hitId == component.selectedId {
            item.action(false)
            self.cancelTapAnimation()
            return
        }
        
        self.interactionSessionId &+= 1
        let sessionId = self.interactionSessionId
        self.tapAnimationSessionId &+= 1
        let tapSessionId = self.tapAnimationSessionId
        
        DispatchQueue.main.async { item.action(false) }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self, tapSessionId == self.tapAnimationSessionId else { return }
            self.isAnimatingTap = false
            if !self.isInteracting { self.forceSetExpanded(false, animated: true) }
        }
        
        guard let liquidIndicator = self.liquidIndicator, let targetRect = self.itemFrames[hitId] else { return }
        
        if liquidIndicator.mode != .dynamic {
            self.lensActivationTimestamp = CACurrentMediaTime()
            liquidIndicator.setMode(.dynamic, animated: false)
        }
        
        liquidIndicator.endInteraction(targetCenter: targetRect.center) { [weak self] in
            guard let self, sessionId == self.interactionSessionId else { return }
            if !self.isInteracting && !self.isAnimatingTap {
                liquidIndicator.clearContentSnapshot()
                self.sendLiquidIndicatorToBack()
            }
        }
    }
    
    private func ensureLiquidIndicatorExists() {
        if self.liquidIndicator == nil {
            let indicator = LiquidIndicator()
            self.contentContainerView.addSubview(indicator)
            self.liquidIndicator = indicator
            
            indicator.onLayoutUpdate = { [weak self] frame, radius, effects in
                guard let self = self else { return }
                let finalEffects = indicator.mode == .static ? nil : effects
                self.updateBackgroundShapes(indicatorFrame: frame, indicatorCornerRadius: radius, effects: finalEffects)
                
                if indicator.mode == .dynamic && !indicator.didReportArrival {
                    self.syncItemsWithIndicator(indicatorFrame: frame, isDynamic: true, isFinishing: indicator.isFinishing)
                }
                
                if indicator.mode == .dynamic || effects == nil {
                    self.backgroundView.render()
                }
            }
            
            indicator.onTargetArrived = { [weak self, weak indicator] in
                guard let self = self, let indicator = indicator else { return }
                indicator.setMode(.static, animated: true)
                self.sendLiquidIndicatorToBack()
                
                if let selectedId = self.component?.selectedId, let rect = self.itemFrames[selectedId] {
                    self.syncItemsWithIndicator(indicatorFrame: rect, isDynamic: false, isFinishing: false)
                }
            }
            
            indicator.onPhysicsSettled = { [weak self, weak indicator] in
                guard let self = self, let indicator = indicator else { return }
                indicator.endInteractionWorkItem?.cancel()
                indicator.endInteractionWorkItem = nil
                
                if indicator.mode != .static {
                    indicator.setMode(.static, animated: true)
                    self.sendLiquidIndicatorToBack()
                    
                    if let selectedId = self.component?.selectedId, let rect = self.itemFrames[selectedId] {
                        self.syncItemsWithIndicator(indicatorFrame: rect, isDynamic: false, isFinishing: false)
                    }
                }
                
                indicator.clearContentSnapshot()
                self.finishingAnimationTargetId = nil
            }
        }
    }
    
    private func sendLiquidIndicatorToBack() {
        if let indicator = self.liquidIndicator {
            self.contentContainerView.sendSubviewToBack(indicator)
        }
    }
    
    func frameForItem(at index: Int) -> CGRect? {
        guard let component = self.component, index >= 0, index < component.items.count else { return nil }
        let id = component.items[index].id
        guard let itemFrame = self.itemFrames[id] else { return nil }
        return self.convert(itemFrame, from: self.contentContainerView)
    }
    
    func hitTestItem(at point: CGPoint) -> AnyHashable? {
        let pointInContainer = self.convert(point, to: self.contentContainerView)
        for (id, rect) in self.itemFrames {
            if rect.contains(pointInContainer) { return id }
        }
        return nil
    }
    
    func viewForItem(id: AnyHashable) -> UIView? { return self.itemViews[id]?.view }
}

// MARK: - Liquid Indicator & Physics

private final class LiquidIndicator: UIView {
    enum Mode { case `static`, dynamic }
    enum InteractionType { case gesture, tap }
    
    struct DynamicEffectsState {
        let glowCenter: CGPoint
        let glowIntensity: Float
        let glowRadius: Float
        let dispersionStrength: Float
    }
    
    private let shapeLayer = CAShapeLayer()
    private let shadowGeneratorLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()
    
    private var topLensLiquidGlassView: LiquidGlassUIView?
    private var displayLink: CADisplayLink?
    
    var onLayoutUpdate: ((CGRect, CGFloat, DynamicEffectsState?) -> Void)?
    var onPhysicsSettled: (() -> Void)?
    var onTargetArrived: (() -> Void)?
    
    private(set) var didReportSettled: Bool = false
    private(set) var didReportArrival: Bool = false
    
    private var targetCenter: CGPoint = .zero
    private var physicsCenter: CGPoint = .zero
    private var velocity: CGPoint = .zero
    
    private var currentSize: CGSize = .zero
    private var targetSize: CGSize = .zero
    private var sizeVelocity: CGSize = .zero
    
    private var shapeDeformation: CGFloat = 0.0
    private var shapeDeformationVelocity: CGFloat = 0.0
    
    private(set) var mode: Mode = .static
    private var staticColor: UIColor = .clear
    private var currentTheme: PresentationTheme?
    
    public var endInteractionWorkItem: DispatchWorkItem?
    private var lastTime: CFTimeInterval = 0
    private(set) var isFinishing: Bool = true
    
    private var cachedCenter: CGPoint = .zero
    private var cachedSize: CGSize = .zero
    private var cachedShapePath: CGPath?
    private var cachedTextureOffset: CGPoint = .zero
    private var cachedTextureScale: CGPoint = CGPoint(x: 1, y: 1)
    
    private var framesSinceLastRender: Int = 0
    private var interactionType: InteractionType = .gesture
    private var lastIndicatorFrame: CGRect = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.addSublayer(self.shadowGeneratorLayer)
        self.shadowGeneratorLayer.mask = self.shadowMaskLayer
        self.shadowGeneratorLayer.fillColor = UIColor.clear.cgColor
        
        self.layer.addSublayer(self.shapeLayer)
        self.shapeLayer.shouldRasterize = false
        self.shapeLayer.rasterizationScale = UIScreen.main.scale
        
        let topLensGlassView = LiquidGlassUIView(frame: frame)
        topLensGlassView.renderMode = .manual
        topLensGlassView.isUserInteractionEnabled = false
        topLensGlassView.isManualBackgroundMode = false
        topLensGlassView.automaticallyRenderOnLayout = false
        topLensGlassView.alpha = 0.0
        
        self.addSubview(topLensGlassView)
        self.topLensLiquidGlassView = topLensGlassView
        self.isUserInteractionEnabled = false
        
        self.setupGlassParameters()
        self.setupShadow()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func updateTheme(_ theme: PresentationTheme) {
        self.currentTheme = theme
        self.setupGlassParameters()
    }
    
    func isAnimating() -> Bool { return self.displayLink != nil }
    
    func forceReset() {
        self.endInteractionWorkItem?.cancel()
        self.endInteractionWorkItem = nil
        self.stopDisplayLink()
        
        self.velocity = .zero
        self.sizeVelocity = .zero
        self.shapeDeformation = 0.0
        self.shapeDeformationVelocity = 0.0
        
        self.lastTime = 0
        self.cachedCenter = .zero
        self.cachedSize = .zero
        self.cachedShapePath = nil
        self.cachedTextureOffset = .zero
        self.cachedTextureScale = CGPoint(x: 1, y: 1)
        self.framesSinceLastRender = 0
        self.lastIndicatorFrame = .zero
        
        self.didReportSettled = false
        self.didReportArrival = false
        
        self.clearContentSnapshot()
        self.shapeLayer.removeAllAnimations()
        self.shadowGeneratorLayer.removeAllAnimations()
        self.topLensLiquidGlassView?.layer.removeAllAnimations()
    }
    
    func setContentSnapshot(_ image: UIImage?) {
        guard let topLensGlassView = self.topLensLiquidGlassView, let image = image else {
            self.clearContentSnapshot()
            return
        }
        topLensGlassView.backgroundProvider?.applyManualSnapshot(image: image)
        topLensGlassView.isManualBackgroundMode = true
    }
    
    func clearContentSnapshot() {
        self.topLensLiquidGlassView?.isManualBackgroundMode = false
        self.topLensLiquidGlassView?.backgroundProvider?.invalidate()
    }
    
    private func setupGlassParameters() {
        guard let topGlass = self.topLensLiquidGlassView else { return }
        let isDarkMode = self.currentTheme?.overallDarkAppearance ?? false
        let cfg = LiquidConfig.shared
        
        var params = LiquidGlassParameters()
        params.textureIndex = 0
        params.opticalPassThrough = 0.0
        params.isGlassColorEnabled = cfg.topLensColorEnabled
        
        if let staticOverride = cfg.indicatorStaticColor {
            params.glassColor = staticOverride
        } else if let theme = self.currentTheme {
            params.glassColor = cfg.getIndicatorColor(theme: theme)
        } else {
            params.glassColor = UIColor.white.withAlphaComponent(0.05)
        }
        
        params.isLightingEnabled = cfg.topLensLightingEnabled && isDarkMode
        params.lightAngle = cfg.topLensLightAngle
        params.lightIntensity = cfg.topLensLightIntensity
        params.ambientStrength = cfg.topLensAmbient
        params.isRefractionEnabled = cfg.topLensRefractionEnabled
        params.thickness = cfg.topLensThickness
        params.refractiveIndex = cfg.topLensRefraction
        params.chromaticAberration = cfg.topLensChromaticAberration
        params.lensDome = cfg.topLensDome
        params.isBlurEnabled = cfg.topLensBlurEnabled
        params.blurRadius = cfg.topLensBlurRadius
        
        topGlass.layerParameters = [params]
    }
    
    private func setupShadow() {
        let cfg = LiquidConfig.shared
        self.shadowGeneratorLayer.shadowColor = cfg.shadowColor.cgColor
        self.shadowGeneratorLayer.shadowOffset = cfg.shadowOffset
        self.shadowGeneratorLayer.shadowRadius = cfg.shadowRadius
    }
    
    func updateStaticColor(_ color: UIColor) {
        let cfg = LiquidConfig.shared
        let finalColor = cfg.indicatorStaticColor ?? color
        self.staticColor = finalColor
        if self.mode == .static {
            self.shapeLayer.fillColor = finalColor.cgColor
        }
        self.setupGlassParameters()
    }
    
    func setMode(_ mode: Mode, animated: Bool) {
        self.mode = mode
        let cfg = LiquidConfig.shared
        let duration = cfg.lensSwitchAnimationDuration
        
        let targetShapeColor = (mode == .static ? self.staticColor : .clear).cgColor
        let targetGlassAlpha: CGFloat = (mode == .dynamic ? 1.0 : 0.0)
        let targetShadowOpacity: Float = (mode == .dynamic ? cfg.shadowOpacity : 0.0)
        
        if mode == .dynamic {
            self.setupGlassParameters()
            self.setupShadow()
        }
        
        if animated {
            let colorAnim = CABasicAnimation(keyPath: "fillColor")
            colorAnim.fromValue = self.shapeLayer.fillColor
            colorAnim.toValue = targetShapeColor
            colorAnim.duration = duration
            self.shapeLayer.add(colorAnim, forKey: "fillColor")
            self.shapeLayer.fillColor = targetShapeColor
            
            let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
            shadowAnim.fromValue = self.shadowGeneratorLayer.shadowOpacity
            shadowAnim.toValue = targetShadowOpacity
            shadowAnim.duration = duration
            self.shadowGeneratorLayer.add(shadowAnim, forKey: "shadowOpacity")
            self.shadowGeneratorLayer.shadowOpacity = targetShadowOpacity
            
            UIView.animate(withDuration: duration) {
                self.topLensLiquidGlassView?.alpha = targetGlassAlpha
            }
        } else {
            self.shapeLayer.fillColor = targetShapeColor
            self.shadowGeneratorLayer.shadowOpacity = targetShadowOpacity
            self.topLensLiquidGlassView?.alpha = targetGlassAlpha
        }
        
        if mode == .static {
            self.onLayoutUpdate?(CGRect.null, 0, nil)
        }
        self.topLensLiquidGlassView?.renderMode = .manual
    }
    
    func configure(rect: CGRect) {
        let cfg = LiquidConfig.shared
        let staticW = cfg.indicatorStaticWidth
        let staticH = cfg.indicatorStaticHeight
        
        let centeredRect = CGRect(
            x: rect.midX - staticW / 2.0,
            y: rect.midY - staticH / 2.0,
            width: staticW,
            height: staticH
        )
        
        self.frame = centeredRect
        self.currentSize = centeredRect.size
        self.targetSize = centeredRect.size
        self.physicsCenter = centeredRect.center
        self.targetCenter = centeredRect.center
        self.sizeVelocity = .zero
        
        self.cachedCenter = centeredRect.center
        self.cachedSize = centeredRect.size
        self.lastIndicatorFrame = centeredRect
        
        self.updateShape(with: centeredRect.size)
        self.topLensLiquidGlassView?.frame = self.bounds
        
        if self.mode == .static {
            let radius = cfg.indicatorStaticRadius > 0 ? cfg.indicatorStaticRadius : (staticH / 2.0)
            self.onLayoutUpdate?(centeredRect, radius, nil)
        }
    }
    
    func startInteraction(at point: CGPoint, type: InteractionType) {
        self.endInteractionWorkItem?.cancel()
        self.endInteractionWorkItem = nil
        
        self.interactionType = type
        self.isFinishing = false
        self.didReportSettled = false
        self.didReportArrival = false
        
        self.velocity = .zero
        self.sizeVelocity = .zero
        self.lastTime = 0
        self.framesSinceLastRender = 0
        self.stopDisplayLink()
        
        let cfg = LiquidConfig.shared
        self.targetSize = CGSize(
            width: cfg.indicatorStaticWidth + cfg.widthExpansion,
            height: cfg.indicatorStaticHeight + cfg.heightExpansion
        )
        
        self.targetCenter = point
        self.physicsCenter = point
        
        self.startDisplayLink()
    }
    
    func updateInteraction(at point: CGPoint) {
        self.targetCenter = point
    }
    
    func endInteraction(targetCenter: CGPoint, completion: @escaping () -> Void) {
        self.targetCenter = targetCenter
        self.isFinishing = true
        self.endInteractionWorkItem?.cancel()
        self.didReportSettled = false
        
        let cfg = LiquidConfig.shared
        self.targetSize = CGSize(width: cfg.indicatorStaticWidth, height: cfg.indicatorStaticHeight)
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.stopDisplayLink()
            self.clearContentSnapshot()
            self.setMode(.static, animated: true)
            completion()
        }
        self.endInteractionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: workItem)
    }
    
    private func startDisplayLink() {
        self.stopDisplayLink()
        self.lastTime = 0
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }
    
    private func stopDisplayLink() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        self.lastTime = 0
    }
    
    @objc private func tick() {
        let currentTime = CACurrentMediaTime()
        if self.lastTime == 0 {
            self.lastTime = currentTime
            return
        }
        
        let dt = min(CGFloat(currentTime - self.lastTime), 0.032)
        self.lastTime = currentTime
        
        let cfg = LiquidConfig.shared
        let screenScale = UIScreen.main.scale
        
        // Physics: Position
        let tension = (self.interactionType == .tap) ? cfg.tapSpringTension : cfg.springTension
        let friction = (self.interactionType == .tap) ? cfg.tapSpringFriction : cfg.springFriction
        
        let forceX = (targetCenter.x - physicsCenter.x) * tension
        let accelerationX = forceX - velocity.x * friction
        velocity.x += accelerationX * dt
        physicsCenter.x += velocity.x * dt
        
        // Physics: Size
        let widthForce = (targetSize.width - currentSize.width) * cfg.sizeSpringTension
        let widthAccel = widthForce - sizeVelocity.width * cfg.sizeSpringFriction
        sizeVelocity.width += widthAccel * dt
        currentSize.width += sizeVelocity.width * dt
        
        let heightForce = (targetSize.height - currentSize.height) * cfg.sizeSpringTension
        let heightAccel = heightForce - sizeVelocity.height * cfg.sizeSpringFriction
        sizeVelocity.height += heightAccel * dt
        currentSize.height += sizeVelocity.height * dt
        
        // Physics: Deformation
        var currentDeformationDelta: CGFloat = 0.0
        if cfg.fluidPhysicsEnabled {
            let velocityX = velocity.x
            var targetDeformation: CGFloat = 0.0
            
            if velocityX > 0 {
                targetDeformation = min(velocityX * cfg.velocityStretchFactor, cfg.maxFluidDeformation)
            } else {
                targetDeformation = max(velocityX * cfg.velocitySquashFactor, -cfg.maxFluidCompression)
            }
            
            let shapeForce = (targetDeformation - shapeDeformation) * cfg.shapeRestitutionTension
            let shapeAccel = shapeForce - (shapeDeformationVelocity * cfg.shapeRestitutionFriction)
            
            shapeDeformationVelocity += shapeAccel * dt
            shapeDeformation += shapeDeformationVelocity * dt
            currentDeformationDelta = shapeDeformation
        } else {
            currentDeformationDelta = min(abs(velocity.x) * cfg.deformationFactor * currentSize.width, cfg.maxDeformation)
        }
        
        // Snapping
        let rawCenter = CGPoint(x: physicsCenter.x, y: targetCenter.y)
        let snappedCenter = CGPoint(
            x: round(rawCenter.x * screenScale) / screenScale,
            y: round(rawCenter.y * screenScale) / screenScale
        )
        
        let rawWidth = currentSize.width + currentDeformationDelta
        var heightCorrection: CGFloat = 0.0
        if currentDeformationDelta >= 0 {
            heightCorrection = currentDeformationDelta * cfg.stretchHeightFactor
        } else {
            heightCorrection = currentDeformationDelta * cfg.compressionHeightFactor
        }
        let rawHeight = currentSize.height - heightCorrection
        
        let snappedSize = CGSize(
            width: max(10.0, round(rawWidth * screenScale) / screenScale),
            height: max(4.0, round(rawHeight * screenScale) / screenScale)
        )
        
        // Arrival & Settlement Logic
        if self.isFinishing, !self.didReportArrival {
            let distToTarget = hypot(targetCenter.x - physicsCenter.x, targetCenter.y - physicsCenter.y)
            if distToTarget < cfg.indicatorArrivalDistanceThreshold {
                self.didReportArrival = true
                self.onTargetArrived?()
            }
        }
        
        let positionDelta = hypot(snappedCenter.x - cachedCenter.x, snappedCenter.y - cachedCenter.y)
        let sizeDelta = hypot(snappedSize.width - cachedSize.width, snappedSize.height - cachedSize.height)
        
        let isPhysicallySettled = self.isFinishing &&
        abs(velocity.x) < cfg.topLensIndicatorFinishDistanceThreshold &&
        abs(velocity.y) < cfg.topLensIndicatorFinishDistanceThreshold &&
        abs(shapeDeformation) < 0.1 &&
        abs(shapeDeformationVelocity) < 0.1 &&
        positionDelta < cfg.topLensIndicatorFinishDistanceThreshold &&
        sizeDelta < cfg.topLensIndicatorFinishDistanceThreshold
        
        if isPhysicallySettled && !didReportSettled {
            self.didReportSettled = true
            self.onPhysicsSettled?()
        }
        
        // Optimization: Skip frame if changes are negligible
        let positionThreshold = cfg.topLensIndicatorPositionThreshold
        let sizeThreshold = cfg.topLensIndicatorSizeThreshold
        if positionDelta < positionThreshold && sizeDelta < sizeThreshold && abs(velocity.x) < 1.0 && abs(shapeDeformationVelocity) < 1.0 && abs(shapeDeformation) < 0.5 && !isPhysicallySettled {
            return
        }
        
        cachedCenter = snappedCenter
        cachedSize = snappedSize
        
        let indicatorFrame = CGRect(
            x: snappedCenter.x - snappedSize.width / 2.0,
            y: snappedCenter.y - snappedSize.height / 2.0,
            width: snappedSize.width,
            height: snappedSize.height
        )
        
        if hypot(indicatorFrame.midX - lastIndicatorFrame.midX, indicatorFrame.midY - lastIndicatorFrame.midY) > positionThreshold || (self.isFinishing && isPhysicallySettled && !didReportSettled) {
            lastIndicatorFrame = indicatorFrame
            if let container = self.superview, let scaler = container.superview, let tabBarView = scaler.superview as? CustomLiquidTabBarView {
                if self.mode == .dynamic && !isPhysicallySettled {
                    tabBarView.syncItemsWithIndicator(indicatorFrame: indicatorFrame, isDynamic: true, isFinishing: self.isFinishing)
                }
            }
        }
        
        // Effects Calculation
        var effectsState: DynamicEffectsState? = nil
        if self.mode == .dynamic || self.isFinishing {
            let totalEnergy = (abs(Float(velocity.x)) * 0.05) + (abs(Float(shapeDeformation)) * 0.1)
            
            var dispersion: Float = 0.0
            if cfg.dispersionEnabled {
                let energyFactor = min(1.0, totalEnergy * cfg.dispersionSensitivity)
                dispersion = cfg.dispersionBase + (cfg.dispersionMax - cfg.dispersionBase) * energyFactor
            }
            
            var gIntensity: Float = 0.0
            var gRadius: Float = 0.0
            if cfg.glowEnabled {
                let glowEnergyFactor = min(1.0, totalEnergy * cfg.glowPhysicsSensitivity)
                gIntensity = cfg.glowBaseIntensity + (glowEnergyFactor * 0.5)
                gRadius = cfg.glowMaxRadius * (0.8 + glowEnergyFactor * 0.2)
            }
            
            effectsState = DynamicEffectsState(
                glowCenter: CGPoint(x: physicsCenter.x * screenScale, y: physicsCenter.y * screenScale),
                glowIntensity: gIntensity,
                glowRadius: gRadius,
                dispersionStrength: dispersion
            )
        }
        
        let dynamicRadius = snappedSize.height / 2.0
        self.onLayoutUpdate?(indicatorFrame, dynamicRadius, effectsState)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.center = snappedCenter
        self.bounds = CGRect(origin: .zero, size: snappedSize)
        
        if sizeDelta > sizeThreshold {
            self.updateShape(with: snappedSize, radius: dynamicRadius)
        }
        
        let shapeData = ShapeData(
            type: .squircle,
            x: Float(snappedSize.width / 2),
            y: Float(snappedSize.height / 2),
            width: Float(snappedSize.width),
            height: Float(snappedSize.height),
            cornerRadius: Float(dynamicRadius),
            layerID: 0
        )
        
        var uvsUpdated = false
        if let container = self.superview {
            let contentSize = container.bounds.size
            let sampWidth = round(indicatorFrame.width * screenScale) / screenScale
            let sampHeight = round(indicatorFrame.height * screenScale) / screenScale
            let sampX = round((indicatorFrame.midX - sampWidth / 2.0) * screenScale) / screenScale
            let sampY = round((indicatorFrame.midY - sampHeight / 2.0) * screenScale) / screenScale
            
            let newOffset = CGPoint(x: sampX / contentSize.width, y: sampY / contentSize.height)
            let newScale = CGPoint(x: sampWidth / contentSize.width, y: sampHeight / contentSize.height)
            
            if hypot(newOffset.x - cachedTextureOffset.x, newOffset.y - cachedTextureOffset.y) > 0.00001 {
                cachedTextureOffset = newOffset
                cachedTextureScale = newScale
                uvsUpdated = true
            }
        }
        
        framesSinceLastRender += 1
        let shouldRender = framesSinceLastRender > cfg.topLensIndicatorRenderSkipFrames
        
        if let topGlass = self.topLensLiquidGlassView {
            topGlass.frame = self.bounds
            
            if sizeDelta > sizeThreshold {
                topGlass.shapes = [shapeData]
            }
            if uvsUpdated {
                topGlass.textureOffset = cachedTextureOffset
                topGlass.textureUvScale = cachedTextureScale
            }
            
            let isVisible = topGlass.alpha > 0.01
            if shouldRender && (self.mode == .dynamic || isVisible) {
                topGlass.render()
            }
        }
        
        if shouldRender {
            framesSinceLastRender = 0
        }
        
        CATransaction.commit()
    }
    
    private func updateShape(with size: CGSize, radius: CGFloat? = nil) {
        let r = radius ?? size.height / 2.0
        let indicatorPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: r)
        let cgPath = indicatorPath.cgPath
        
        let pathChanged = cachedShapePath == nil || !cgPath.__equalTo(cachedShapePath!)
        if pathChanged {
            cachedShapePath = cgPath
            self.shapeLayer.path = cgPath
            self.shadowGeneratorLayer.path = cgPath
            self.shadowGeneratorLayer.shadowPath = cgPath
            
            let inset: CGFloat = 1.5
            let holeRect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let holePath = UIBezierPath(roundedRect: holeRect, cornerRadius: holeRect.height / 2.0)
            
            let bigRect = self.bounds.insetBy(dx: -500, dy: -500)
            let maskPath = UIBezierPath(rect: bigRect)
            maskPath.append(holePath)
            maskPath.usesEvenOddFillRule = true
            
            self.shadowMaskLayer.path = maskPath.cgPath
            self.shadowMaskLayer.fillRule = .evenOdd
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.shapeLayer.frame = self.bounds
        self.shadowGeneratorLayer.frame = self.bounds
        self.shadowMaskLayer.frame = self.shadowGeneratorLayer.bounds
        self.topLensLiquidGlassView?.frame = self.bounds
    }
}

fileprivate extension CGRect { var center: CGPoint { CGPoint(x: midX, y: midY) } }
