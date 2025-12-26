// TabBarComponent.swift

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

// MARK: - Protocol

protocol TabBarImplementation: UIView {
    func update(
        component: TabBarComponent,
        availableSize: CGSize,
        state: EmptyComponentState,
        transition: ComponentTransition
    ) -> CGSize
    
    func frameForItem(at index: Int) -> CGRect?
    func hitTestItem(at point: CGPoint) -> AnyHashable?
    func viewForItem(id: AnyHashable) -> UIView?
}

// MARK: - Main Component

public final class TabBarComponent: Component {
    public final class Item: Equatable {
        public let item: UITabBarItem
        public let action: (Bool) -> Void
        public let contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?
        
    var id: AnyHashable { AnyHashable(ObjectIdentifier(self.item)) }
        
        public init(item: UITabBarItem, action: @escaping (Bool) -> Void, contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?) {
            self.item = item
            self.action = action
            self.contextAction = contextAction
        }
        
        public static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs === rhs { return true }
            if lhs.item !== rhs.item { return false }
            if (lhs.contextAction == nil) != (rhs.contextAction == nil) { return false }
            return true
        }
    }
    
    public let theme: PresentationTheme
    public let items: [Item]
    public let selectedId: AnyHashable?
    public let isTablet: Bool
    
    public init(theme: PresentationTheme, items: [Item], selectedId: AnyHashable?, isTablet: Bool) {
        self.theme = theme
        self.items = items
        self.selectedId = selectedId
        self.isTablet = isTablet
    }
    
    public static func ==(lhs: TabBarComponent, rhs: TabBarComponent) -> Bool {
        if lhs.theme !== rhs.theme { return false }
        if lhs.items != rhs.items { return false }
        if lhs.selectedId != rhs.selectedId { return false }
        if lhs.isTablet != rhs.isTablet { return false }
        return true
    }
    
    public final class View: UIView {
        private let contextGestureContainerView: ContextControllerSourceView
        private var implementationView: (UIView & TabBarImplementation)?
        
        private var component: TabBarComponent?
        private var itemWithActiveContextGesture: AnyHashable?
        
        private static let useLegacyTabBar: Bool = false
        
        public override init(frame: CGRect) {
            self.contextGestureContainerView = ContextControllerSourceView()
            self.contextGestureContainerView.isGestureEnabled = true
            super.init(frame: frame)
            self.addSubview(self.contextGestureContainerView)
            self.setupContextGestures()
        }
        
        required public init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        private func setupContextGestures() {
            self.contextGestureContainerView.shouldBegin = { [weak self] point in
                guard let self, let component = self.component, let implementation = self.implementationView else { return false }

                let id: AnyHashable?

                if let liquidView = implementation as? CustomLiquidTabBarView {
                    if liquidView.isInteracting { return false }
                    id = liquidView.hitTestItem(at: point)
                } else {
                    id = implementation.hitTestItem(at: point)
                }

                guard let itemId = id, let item = component.items.first(where: { $0.id == itemId }) else {
                    (implementation as? CustomLiquidTabBarView)?.cancelTapAnimation()
                    return false
                }

                guard item.contextAction != nil else { return false }

                if let liquidView = implementation as? CustomLiquidTabBarView {
                    liquidView.beginTapAnimation(for: itemId)
                }

                self.itemWithActiveContextGesture = itemId

                let startPoint = point
                self.contextGestureContainerView.contextGesture?.externalUpdated = { [weak self] _, currentPoint in
                    guard let self else { return }

                    let dx = abs(startPoint.x - currentPoint.x)
                    let dy = abs(startPoint.y - currentPoint.y)

                    if dx > 10.0 && dx > dy * 1.5 || dx > 20.0 || dy > 20.0 {
                        (self.implementationView as? CustomLiquidTabBarView)?.cancelTapAnimation()
                        self.contextGestureContainerView.contextGesture?.cancel()
                    }
                }

                return true
            }

            self.contextGestureContainerView.customActivationProgress = { _, _ in return }

            self.contextGestureContainerView.activated = { [weak self] gesture, _ in
                guard let self, let component = self.component, let itemWithActiveContextGesture = self.itemWithActiveContextGesture else { return }

                (self.implementationView as? CustomLiquidTabBarView)?.cancelTapAnimation()

                var itemView: ItemComponent.View?
                if let legacyView = self.implementationView as? LegacyTabBarView {
                     itemView = (legacyView.viewForItem(id: itemWithActiveContextGesture)) as? ItemComponent.View
                } else if let liquidView = self.implementationView as? CustomLiquidTabBarView {
                    if let liquidItemView = liquidView.viewForItem(id: itemWithActiveContextGesture) as? LiquidItemComponent.View {
                        itemView = liquidItemView.getInnerView()
                    }
                } else if let nativeView = self.implementationView as? NativeTabBarView {
                     nativeView.cancelInternalGestures()
                     itemView = (nativeView.viewForItem(id: itemWithActiveContextGesture)) as? ItemComponent.View
                }

                guard let finalItemView = itemView, let item = component.items.first(where: { $0.id == itemWithActiveContextGesture }) else { return }
                item.contextAction?(gesture, finalItemView.contextContainerView)
            }
        }
        
        private func requiredImplementationType() -> TabBarImplementation.Type {
            if #available(iOS 26.0, *) { return NativeTabBarView.self }
            else if !TabBarComponent.View.useLegacyTabBar { return CustomLiquidTabBarView.self }
            else { return LegacyTabBarView.self }
        }
        
        func update(component: TabBarComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let availableSize = CGSize(width: min(500.0, availableSize.width), height: availableSize.height)
            self.component = component
            self.overrideUserInterfaceStyle = component.theme.overallDarkAppearance ? .dark : .light
            
            let requiredType = self.requiredImplementationType()
            
            if self.implementationView == nil || type(of: self.implementationView!) != requiredType {
                self.implementationView?.removeFromSuperview()
                let newImplementation = requiredType.init(frame: .zero)
                self.contextGestureContainerView.addSubview(newImplementation)
                self.implementationView = newImplementation
            }
            
            guard let implementationView = self.implementationView else { return .zero }
            
            let size = implementationView.update(component: component, availableSize: availableSize, state: state, transition: transition)
            
            let containerSize: CGSize = (implementationView is NativeTabBarView) ? CGSize(width: availableSize.width, height: 62.0) : size
            
            transition.setFrame(view: self.contextGestureContainerView, frame: CGRect(origin: CGPoint(), size: containerSize))
            transition.setFrame(view: implementationView, frame: CGRect(origin: CGPoint(), size: containerSize))
            
            return containerSize
        }
        
        public func frameForItem(at index: Int) -> CGRect? {
            guard let implementation = self.implementationView, let rawFrame = implementation.frameForItem(at: index) else { return nil }
            return self.convert(rawFrame, from: implementation)
        }
    }
    
    public func makeView() -> View { View(frame: CGRect()) }
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

// MARK: - Shared Item Component

final class ItemComponent: Component {
    let item: TabBarComponent.Item
    let theme: PresentationTheme
    let isSelected: Bool
    
    init(item: TabBarComponent.Item, theme: PresentationTheme, isSelected: Bool) {
        self.item = item
        self.theme = theme
        self.isSelected = isSelected
    }
    
    static func ==(lhs: ItemComponent, rhs: ItemComponent) -> Bool {
        if lhs.item != rhs.item { return false }
        if lhs.theme !== rhs.theme { return false }
        if lhs.isSelected != rhs.isSelected { return false }
        return true
    }
    
    final class View: UIView {
        let contextContainerView = ContextExtractedContentContainingView()
        private var imageIcon: ComponentView<Empty>?
        private var animationIcon: ComponentView<Empty>?
        private let title = ComponentView<Empty>()
        private var badge: ComponentView<Empty>?
        private var component: ItemComponent?
        private weak var state: EmptyComponentState?
        private var setImageListener: Int?
        private var setSelectedImageListener: Int?
        private var setBadgeListener: Int?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(self.contextContainerView)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        deinit {
            if let component = self.component {
                if let l = setImageListener { component.item.item.removeSetImageListener(l) }
                if let l = setSelectedImageListener { component.item.item.removeSetSelectedImageListener(l) }
                if let l = setBadgeListener { component.item.item.removeSetBadgeListener(l) }
            }
        }
        
        func playSelectionAnimation() {
            (self.animationIcon?.view as? LottieComponent.View)?.playOnce()
        }
        
        func update(component: ItemComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let previousComponent = self.component
            
            if previousComponent?.item.item !== component.item.item {
                if let l = setImageListener { self.component?.item.item.removeSetImageListener(l) }
                if let l = setSelectedImageListener { self.component?.item.item.removeSetSelectedImageListener(l) }
                if let l = setBadgeListener { self.component?.item.item.removeSetBadgeListener(l) }
                self.setImageListener = component.item.item.addSetImageListener { [weak self] _ in self?.state?.updated(transition: .immediate, isLocal: true) }
                self.setSelectedImageListener = component.item.item.addSetSelectedImageListener { [weak self] _ in self?.state?.updated(transition: .immediate, isLocal: true) }
                self.setBadgeListener = UITabBarItem_addSetBadgeListener(component.item.item) { [weak self] _ in self?.state?.updated(transition: .immediate, isLocal: true) }
            }
            
            self.component = component
            self.state = state
            
            if let animationName = component.item.item.animationName {
                if self.imageIcon != nil { self.imageIcon = nil; self.imageIcon?.view?.removeFromSuperview() }
                let animationIcon = self.animationIcon ?? ComponentView()
                self.animationIcon = animationIcon
                
                let iconSize = animationIcon.update(
                    transition: transition,
                    component: AnyComponent(LottieComponent(
                        content: LottieComponent.AppBundleContent(name: animationName),
                        color: component.isSelected ? component.theme.rootController.tabBar.selectedTextColor : component.theme.rootController.tabBar.textColor,
                        size: CGSize(width: 48, height: 48)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 48, height: 48)
                )
                let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: -4.0), size: iconSize).offsetBy(dx: component.item.item.animationOffset.x, dy: component.item.item.animationOffset.y)
                if let view = animationIcon.view {
                    if view.superview == nil { self.contextContainerView.contentView.addSubview(view) }
                    transition.setFrame(view: view, frame: iconFrame)
                }
            } else {
                if self.animationIcon != nil { self.animationIcon = nil; self.animationIcon?.view?.removeFromSuperview() }
                let imageIcon = self.imageIcon ?? ComponentView()
                self.imageIcon = imageIcon
                
                let iconSize = imageIcon.update(transition: transition, component: AnyComponent(Image(image: component.isSelected ? component.item.item.selectedImage : component.item.item.image, contentMode: .center)), environment: {}, containerSize: CGSize(width: 100, height: 100))
                let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: 3.0), size: iconSize)
                if let view = imageIcon.view {
                    if view.superview == nil { self.contextContainerView.contentView.addSubview(view) }
                    transition.setFrame(view: view, frame: iconFrame)
                }
            }
            
            let titleSize = self.title.update(transition: .immediate, component: AnyComponent(MultilineTextComponent(text: .plain(NSAttributedString(string: component.item.item.title ?? " ", font: Font.semibold(10.0), textColor: component.isSelected ? component.theme.rootController.tabBar.selectedTextColor : component.theme.rootController.tabBar.textColor)))), environment: {}, containerSize: availableSize)
            let titleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) * 0.5), y: availableSize.height - 8.0 - titleSize.height), size: titleSize)
            if let view = self.title.view {
                if view.superview == nil { self.contextContainerView.contentView.addSubview(view) }
                view.frame = titleFrame
            }
            
            if let badgeText = component.item.item.badgeValue, !badgeText.isEmpty {
                let badge = self.badge ?? ComponentView()
                self.badge = badge
                let badgeSize = badge.update(transition: transition, component: AnyComponent(TextBadgeComponent(text: badgeText, font: Font.regular(13.0), background: component.theme.rootController.tabBar.badgeBackgroundColor, foreground: component.theme.rootController.tabBar.badgeTextColor, insets: UIEdgeInsets(top: 0.0, left: 6.0, bottom: 1.0, right: 6.0))), environment: {}, containerSize: availableSize)
                let badgeFrame = CGRect(origin: CGPoint(x: floor(availableSize.width / 2.0) + 25.0 - badgeSize.width - 1.0, y: 5.0), size: badgeSize)
                if let view = badge.view {
                    if view.superview == nil { self.contextContainerView.contentView.addSubview(view) }
                    transition.setFrame(view: view, frame: badgeFrame)
                }
            } else if let badge = self.badge {
                self.badge = nil
                badge.view?.removeFromSuperview()
            }
            
            transition.setFrame(view: self.contextContainerView, frame: CGRect(origin: .zero, size: availableSize))
            self.contextContainerView.contentRect = CGRect(origin: .zero, size: availableSize)
            return availableSize
        }
    }
    
    func makeView() -> View { View(frame: CGRect()) }
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

// MARK: - Legacy Implementation

final class LegacyTabBarView: UIView, TabBarImplementation {
    private let backgroundView = GlassBackgroundView()
    private let selectionView = GlassBackgroundView.ContentImageView()
    private var itemViews: [AnyHashable: ComponentView<Empty>] = [:]
    
    private var component: TabBarComponent?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.backgroundView)
        self.backgroundView.contentView.addSubview(self.selectionView)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:))))
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func update(component: TabBarComponent, availableSize: CGSize, state: EmptyComponentState, transition: ComponentTransition) -> CGSize {
        self.component = component
        let innerInset: CGFloat = 3.0
        
        let itemSize = CGSize(width: min(94.0, floor((availableSize.width - innerInset * 2.0) / CGFloat(component.items.count))), height: 56.0)
        let contentHeight = itemSize.height + innerInset * 2.0
        var contentWidth: CGFloat = innerInset
        
        if self.selectionView.image?.size.height != itemSize.height {
            self.selectionView.image = generateStretchableFilledCircleImage(radius: itemSize.height * 0.5, color: .white)?.withRenderingMode(.alwaysTemplate)
        }
        self.selectionView.tintColor = component.theme.list.itemPrimaryTextColor.withMultipliedAlpha(0.05)
        
        var validIds: [AnyHashable] = []
        var selectionFrame: CGRect?
        
        for item in component.items {
            validIds.append(item.id)
            let itemView = self.itemViews[item.id] ?? ComponentView()
            self.itemViews[item.id] = itemView
            
            let isItemSelected = component.selectedId == item.id
            let _ = itemView.update(transition: transition, component: AnyComponent(ItemComponent(item: item, theme: component.theme, isSelected: isItemSelected)), environment: {}, containerSize: itemSize)
            let itemFrame = CGRect(origin: CGPoint(x: contentWidth, y: floor((contentHeight - itemSize.height) * 0.5)), size: itemSize)
            
            if let view = itemView.view as? ItemComponent.View {
                if view.superview == nil {
                    view.isUserInteractionEnabled = false
                    self.addSubview(view)
                }
                transition.setFrame(view: view, frame: itemFrame)
                if isItemSelected { view.playSelectionAnimation() }
            }
            if isItemSelected { selectionFrame = itemFrame }
            contentWidth += itemFrame.width
        }
        
        var removeIds: [AnyHashable] = []
        for (id, itemView) in self.itemViews {
            if !validIds.contains(id) {
                removeIds.append(id)
                itemView.view?.removeFromSuperview()
            }
        }
        for id in removeIds { self.itemViews.removeValue(forKey: id) }
        
        if let selectionFrame {
            self.selectionView.isHidden = false
            transition.setFrame(view: self.selectionView, frame: selectionFrame)
        } else {
            self.selectionView.isHidden = true
        }
        
        let size = CGSize(width: min(availableSize.width, contentWidth + innerInset), height: contentHeight)
        transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(), size: size))
        
        // Resolve color using LiquidConfig logic (handles manual overrides and dark mode)
        let barColor = LiquidConfig.shared.getBarColor(theme: component.theme)
        
        self.backgroundView.update(size: size, cornerRadius: size.height * 0.5, isDark: component.theme.overallDarkAppearance, tintColor: .init(kind: .panel, color: barColor), transition: transition)
        return size
    }
    
    @objc private func onTapGesture(_ recognizer: UITapGestureRecognizer) {
        guard let component = self.component, case .ended = recognizer.state else { return }
        let point = recognizer.location(in: self)
        
        var closest: (AnyHashable, CGFloat)?
        for (id, itemView) in self.itemViews {
            guard let view = itemView.view else { continue }
            let dist = abs(point.x - view.center.x)
            if closest == nil || dist < closest!.1 { closest = (id, dist) }
        }
        
        if let (id, _) = closest, let item = component.items.first(where: { $0.id == id }) {
            item.action(false)
        }
    }
    
    func frameForItem(at index: Int) -> CGRect? {
        guard let component = self.component, index >= 0, index < component.items.count else { return nil }
        return self.itemViews[component.items[index].id]?.view?.frame
    }
    
    func hitTestItem(at point: CGPoint) -> AnyHashable? {
        for (id, itemView) in self.itemViews {
            if let view = itemView.view, view.frame.contains(point) { return id }
        }
        return nil
    }
    
    func viewForItem(id: AnyHashable) -> UIView? { return self.itemViews[id]?.view }
}


// MARK: - Native Implementation

final class NativeTabBarView: UIView, TabBarImplementation, UITabBarDelegate {
    private let nativeTabBar = UITabBar()
    private var itemViews: [AnyHashable: ComponentView<Empty>] = [:]
    private var selectedItemViews: [AnyHashable: ComponentView<Empty>] = [:]
    private var component: TabBarComponent?
    
    private var nativeItemContainers: [Int: UIView] = [:]
    private var nativeSelectedItemContainers: [Int: UIView] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let itemFont = Font.semibold(10.0)
        let itemColor: UIColor = .clear
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: itemColor, .font: itemFont]
        
        let app = self.nativeTabBar.standardAppearance
        app.stackedLayoutAppearance.normal.titleTextAttributes = attributes
        app.stackedLayoutAppearance.selected.titleTextAttributes = attributes
        app.inlineLayoutAppearance.normal.titleTextAttributes = attributes
        app.inlineLayoutAppearance.selected.titleTextAttributes = attributes
        app.compactInlineLayoutAppearance.normal.titleTextAttributes = attributes
        app.compactInlineLayoutAppearance.selected.titleTextAttributes = attributes
        
        self.addSubview(self.nativeTabBar)
        self.nativeTabBar.delegate = self
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func update(component: TabBarComponent, availableSize: CGSize, state: EmptyComponentState, transition: ComponentTransition) -> CGSize {
        let previousComponent = self.component
        self.component = component
        
        if previousComponent?.items.map(\.item.title) != component.items.map(\.item.title) {
            self.nativeTabBar.items = component.items.enumerated().map { UITabBarItem(title: $0.element.item.title, image: nil, tag: $0.offset) }
            for (_, itemView) in self.itemViews { itemView.view?.removeFromSuperview() }
            for (_, selectedItemView) in self.selectedItemViews { selectedItemView.view?.removeFromSuperview() }
            if let index = component.items.firstIndex(where: { $0.id == component.selectedId }) {
                self.nativeTabBar.selectedItem = self.nativeTabBar.items?[index]
            }
        }
        
        self.nativeTabBar.frame = CGRect(origin: .zero, size: CGSize(width: availableSize.width, height: component.isTablet ? 74.0 : 83.0))
        self.nativeTabBar.layoutSubviews()
        
        self.findInternalContainers()
        
        let itemSize = self.nativeItemContainers[0]?.bounds.size ?? CGSize(width: 50, height: 50)
        
        for (index, item) in component.items.enumerated() {
            let itemView = self.itemViews[item.id] ?? ComponentView()
            self.itemViews[item.id] = itemView
            let selectedItemView = self.selectedItemViews[item.id] ?? ComponentView()
            self.selectedItemViews[item.id] = selectedItemView
            
            let _ = itemView.update(transition: transition, component: AnyComponent(ItemComponent(item: item, theme: component.theme, isSelected: false)), environment: {}, containerSize: itemSize)
            let _ = selectedItemView.update(transition: transition, component: AnyComponent(ItemComponent(item: item, theme: component.theme, isSelected: true)), environment: {}, containerSize: itemSize)
            
            if let view = itemView.view, let selView = selectedItemView.view {
                if view.superview == nil, let container = self.nativeItemContainers[index] { container.addSubview(view) }
                if selView.superview == nil, let selContainer = self.nativeSelectedItemContainers[index] { selContainer.addSubview(selView) }
                
                if let parent = view.superview {
                    let frame = CGRect(origin: CGPoint(x: floor((parent.bounds.width - itemSize.width) * 0.5), y: floor((parent.bounds.height - itemSize.height) * 0.5)), size: itemSize)
                    transition.setFrame(view: view, frame: frame)
                    transition.setFrame(view: selView, frame: frame)
                }
            }
        }
        return CGSize(width: availableSize.width, height: 62.0)
    }
    
    private func findInternalContainers() {
        self.nativeItemContainers.removeAll()
        self.nativeSelectedItemContainers.removeAll()
        var contentIndex = 0, selectedContentIndex = 0
        
        func traverse(_ view: UIView) {
            let name = NSStringFromClass(type(of: view))
            if name.hasSuffix("TabButton") {
                if let supername = view.superview.map({ NSStringFromClass(type(of: $0)) }) {
                    if supername.hasSuffix("SelectedContentView") { self.nativeSelectedItemContainers[selectedContentIndex] = view; selectedContentIndex += 1 }
                    else if supername.hasSuffix("ContentView") { self.nativeItemContainers[contentIndex] = view; contentIndex += 1 }
                }
            }
            view.subviews.forEach(traverse)
        }
        self.nativeTabBar.subviews.forEach(traverse)
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let component = self.component, let index = tabBar.items?.firstIndex(of: item), index < component.items.count else { return }
        component.items[index].action(false)
    }
    
    func cancelInternalGestures() {
        func cancel(view: UIView) {
            view.gestureRecognizers?.forEach { if NSStringFromClass(type(of: $0)).contains("sSelectionGestureRecognizer") { $0.state = .cancelled } }
            view.subviews.forEach(cancel)
        }
        cancel(view: self.nativeTabBar)
    }
    
    func frameForItem(at index: Int) -> CGRect? {
        guard let component = self.component, index >= 0, index < component.items.count, let view = self.itemViews[component.items[index].id]?.view else { return nil }
        return view.convert(view.bounds, to: self)
    }
    
    func hitTestItem(at point: CGPoint) -> AnyHashable? {
        guard let component = self.component else { return nil }
        for item in component.items {
            if let view = self.itemViews[item.id]?.view, view.convert(view.bounds, to: self).contains(point) {
                return item.id
            }
        }
        return nil
    }
    
    func viewForItem(id: AnyHashable) -> UIView? { self.selectedItemViews[id]?.view }
}


