//
//  FLPullUpViewController.swift
//  FLPullUpViewController
//
//  Created by Felix Li on 1/12/15.
//  Copyright © 2015 101medialab. All rights reserved.
//

import Foundation

public protocol PullUpDelegate: class {
    
    func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController)
}

// OPTIONAL
public extension PullUpDelegate {
    
    func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController) { }
}

private let staticPullBarHeight: CGFloat = 20
private let containerPullAnimation: TimeInterval = 0.3

private class ContainerVC: UIViewController {
    
    public let darkScreenView = DarkScreenView()
    public let containerView = UIView()
    public let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    public var addCornerRadius = false
    
    public var compressViewForLargeScreens = true
    public var maxWidthForCompressedView: CGFloat = 700
    
    public var rootViewController = UIViewController()
    
    public var originalPullDistance: CGFloat?
    public var pullUpDistance: CGFloat = 0
    public var showPullUpBar: Bool = false
    
    public var didDismissController: (() -> Void)?
    
    lazy private var pullTabImageView: UIImageView = {
        
        let imageView = UIImageView(image: .dragIndicatorIcon)
        return imageView
    }()


    // MARK: Life Cycle
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: containerPullAnimation) {
            
            self.darkScreenView.hide = false
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let pullBarHeight = (self.showPullUpBar)
            ? staticPullBarHeight
            : 0
        
        var containerX: CGFloat = 0
        var containerWidth: CGFloat = view.bounds.width
        
        if compressViewForLargeScreens {
            containerWidth =  min(view.bounds.width, maxWidthForCompressedView)
            containerX = (view.bounds.width - containerWidth) / 2
        }
        
        if let navVC = rootViewController as? UINavigationController {
            
            navVC.navigationBar.frame = CGRect(x: navVC.navigationBar.frame.origin.x, y: pullBarHeight, width: navVC.navigationBar.frame.width, height: 44)
        }
        
        self.darkScreenView.frame = view.bounds
        
        if self.containerView.frame == CGRect.zero {
            
            self.containerView.frame = CGRect(x: containerX, y: view.bounds.height, width: containerWidth, height: view.bounds.height)
            self.darkScreenView.updateFrame()
        }
                
        UIView.animate(withDuration: containerPullAnimation, delay: 0, options: .beginFromCurrentState, animations: {
            
            self.containerView.frame.origin = CGPoint(x: containerX, y: self.view.frame.height - self.pullUpDistance)
            self.containerView.frame.size = CGSize(width: containerWidth, height: max(self.pullUpDistance, (self.originalPullDistance ?? 0)))
                        
            if #available(iOS 11.0, *) {
                self.rootViewController.additionalSafeAreaInsets = UIEdgeInsets(top: pullBarHeight, left: 0, bottom: 0, right: 0)
            }
                        
            // Setting rootViewController as frame
            self.rootViewController.view.frame = CGRect(x: 0, y: 0, width: self.containerView.bounds.width, height: self.containerView.frame.height)
 
            self.darkScreenView.updateFrame()
            
        }) { complete in
            
            if self.showPullUpBar {
                
                self.pullTabImageView.frame = CGRect(x: (self.containerView.bounds.width - self.pullTabImageView.bounds.width) / 2,
                                                     y: (staticPullBarHeight - self.pullTabImageView.bounds.height) / 2,
                                                     width: self.pullTabImageView.bounds.width,
                                                     height: self.pullTabImageView.bounds.height)
                
                self.containerView.addSubview(self.pullTabImageView)
            }else{
                self.pullTabImageView.removeFromSuperview()
            }
            
            self.blurEffectView.frame = self.containerView.bounds
            self.darkScreenView.backgroundColor = UIColor.clear
            
            if #available(iOS 11.0, *) {
                
                if self.addCornerRadius {
                    self.containerView.layer.masksToBounds = true
                    self.containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    self.containerView.layer.cornerRadius = 8
                }else{
                    self.containerView.layer.cornerRadius = 0
                }
            }
        }
    }
   
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        darkScreenView.backgroundColor = UIColor.black
    }
}

public class FLPullUpViewController {
    
    public static let layoutSizeFitting: CGFloat = -1
    
    // View Controllers
    private let viewController = ContainerVC()
    public private(set) var rootViewController: UIViewController {
        get { self.viewController.rootViewController }
        set {
            self.viewController.removeChild(child: rootViewController)
            self.viewController.rootViewController = newValue
            self.setupPullUpVC()
        }
    }
    
    // Gestures
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    
    // State
    private var isPanning = false
    private var keyboardExpanded: Bool = false
    
    // Delegate
    public weak var delegate: PullUpDelegate?
    
    
    // flags
    public var useSystemLayoutSizeFitting: Bool = false
    public var pullToClose: Bool = true {
        didSet{
            if pullToClose {
                self.viewController.containerView.addGestureRecognizer(panGesture)
            }else if self.viewController.containerView.gestureRecognizers?.contains(panGesture) == true{
                self.viewController.containerView.removeGestureRecognizer(panGesture)
            }
        }
    }
    
    public var compressViewForLargeScreens: Bool {
        get { self.viewController.compressViewForLargeScreens }
        set { self.viewController.compressViewForLargeScreens = newValue }
    }
    
    public var maxWidthForCompressedView: CGFloat {
        get { self.viewController.maxWidthForCompressedView }
        set { self.viewController.maxWidthForCompressedView = newValue }
    }
    
    @available(iOS 11.0, *)
    public var addCornerRadius: Bool {
        get { self.viewController.addCornerRadius }
        set { self.viewController.addCornerRadius = newValue }
    }
    
    public var setBlackBorder: Bool = false {
        didSet{
            if setBlackBorder {
                viewController.containerView.layer.borderColor = UIColor.black.cgColor
                viewController.containerView.layer.borderWidth = 1
            }else{
                viewController.containerView.layer.borderColor = UIColor.black.cgColor
                viewController.containerView.layer.borderWidth = 0
            }
        }
    }
    
    private var blurBackground = false {
        didSet{
            updateContainer()
        }
    }
    
    private var originalPullDistance: CGFloat? {
        get {
            if keyboardExpanded {
                let pullBarHeight = (self.showPullUpBar) ? staticPullBarHeight : 0
                if #available(iOS 11.0, *) {
                    
                    return self.viewController.view.bounds.height - pullBarHeight - self.viewController.view.safeAreaInsets.top
                } else {
                    return self.viewController.view.bounds.height - pullBarHeight
                }
                
            }else{
                return self.viewController.originalPullDistance
            }
        }
        set { self.viewController.originalPullDistance = newValue }
    }

    public var pullUpDistance: CGFloat {
        get { self.viewController.pullUpDistance }
        set {
            var newDistance = newValue
            
             if newValue == Self.layoutSizeFitting {
                
                var intrinsicSizeVC = self.rootViewController
                
                if let navVC = intrinsicSizeVC as? UINavigationController,
                    let viewController = navVC.visibleViewController {
                    intrinsicSizeVC = viewController
                }
                
                if #available(iOS 11.0, *) {
                    
                    intrinsicSizeVC.view.invalidateIntrinsicContentSize() // invalidate before layout
                    intrinsicSizeVC.view.setNeedsLayout()

                    let pullBarHeight = (self.showPullUpBar) ? staticPullBarHeight : 0

                    newDistance = intrinsicSizeVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + pullBarHeight
                    
                } else {
                    newDistance = intrinsicSizeVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                }
                
                // Need to call again in order to set view size to update correctly when pull distance has not changed
                intrinsicSizeVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            }
            
            self.viewController.pullUpDistance = newDistance
            if originalPullDistance == nil {
                self.originalPullDistance = self.pullUpDistance
            }
            viewController.view.setNeedsLayout()
        }
    }
    
    public var showPullUpBar: Bool = false {
        didSet{
            viewController.showPullUpBar = showPullUpBar
            viewController.view.setNeedsLayout()
        }
    }
        
    public var expandWithKeyboard: Bool = false
    
    // Imitate View Controller
    // Grab Actual View Controller info
    public var presentingViewController: UIViewController? {
        return viewController.presentingViewController
    }
    
    public var view: UIView {
        return viewController.view
    }
    
    // Initialize FLPullUpViewController
    
    public init(){
        defaultConfiguration()
    }
    
    public convenience init(rootViewController: UIViewController) {
        self.init()
        self.rootViewController = rootViewController
    }
        
    private func updateContainer() {
        
        viewController.blurEffectView.removeFromSuperview()
        viewController.removeChild(child: rootViewController)
        viewController.didDismissController = { [weak self] in
            
            guard let wself = self else { return }
            NotificationCenter.default.removeObserver(wself)
        }
        
        if blurBackground{
            self.viewController.containerView.backgroundColor = UIColor.clear
            self.viewController.containerView.addSubview(viewController.blurEffectView)
            self.viewController.addChild(child: rootViewController, to: viewController.blurEffectView)
        }else{
            self.viewController.containerView.backgroundColor = UIColor.clear
            self.viewController.addChild(child: rootViewController, to: self.viewController.containerView)
        }
    }
    
    // MARK: Update appearance
    
    private func setupPullUpVC(){
        
        if let navVC = rootViewController as? UINavigationController,
            let displayingVC = navVC.viewControllers.first {
            
            displayingVC.automaticallyAdjustsScrollViewInsets = false
            
            navVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
            
            navVC.navigationBar.backgroundColor = UIColor.clear
            navVC.view.backgroundColor = UIColor.clear
        }
        
        updateContainer()
        
        viewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    // MARK: Initialization
    private func defaultConfiguration() {
        
        viewController.view.clipsToBounds = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panContainer(gesture:)))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesturePressed(gesture:)))
        
        //always fill the view
        self.viewController.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
        if pullToClose {
            self.viewController.containerView.addGestureRecognizer(panGesture)
        }
        
        // initial frame to animate from
        viewController.darkScreenView.frame = viewController.view.bounds
        viewController.darkScreenView.addGestureRecognizer(tapGesture)
        viewController.darkScreenView.hide = true
        viewController.darkScreenView.maskedView = self.viewController.containerView
        
        setupPullUpVC()
        
        updateContainer()
        
        viewController.view.addSubview(self.viewController.darkScreenView)
        viewController.view.addSubview(self.viewController.containerView)
    }
    
    //MARK: Setter
    
    public func setRootViewController(rootViewController: UIViewController){
        
        self.rootViewController = rootViewController
    }
    
    public func resetOriginalPullDistance() {
        self.originalPullDistance = nil
        
        if self.useSystemLayoutSizeFitting, !keyboardExpanded {
            
            self.pullUpDistance = Self.layoutSizeFitting
            self.viewController.view.layoutIfNeeded()
        }
    }
    
    // MARK: Present pullUpVC
    //  .presentViewController does not check for UINavigationController, UIPageViewController cases
    public func show(_ completion: (() -> Void)? = nil){
        
        /* Prevent Error:
         
         Fatal Exception: NSInvalidArgumentException
         Application tried to present modally an active controller
         
         */
        
        guard
            self.viewController.presentingViewController == nil,
            let window = UIApplication.shared.keyWindow,
            var currentVC = window.rootViewController
            
            else {  return
        }
        
        while (currentVC.presentedViewController != nil) {
            if let presentedVC = currentVC.presentedViewController {
                currentVC = presentedVC
            }
        }
        
        self.viewController.containerView.frame = CGRect.zero
        
        currentVC.present(self.viewController, animated: false) {
            
            if self.pullUpDistance == 0 {
                
                if self.useSystemLayoutSizeFitting {
                    self.pullUpDistance = Self.layoutSizeFitting
                }else{
                    self.pullUpDistance = self.viewController.view.bounds.height / 2
                }
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardOpened(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardClosed(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            completion?()
        }
    }
    
    public func dismiss(completion: (() -> Void)? = nil){
        
        UIView.setAnimationsEnabled(true)
        
        self.pullUpDistance = 0
        
        UIView.animate(withDuration: containerPullAnimation, animations: { () -> Void in
            
            self.viewController.darkScreenView.hide = true
            
        }) { complete in
            
            if let delegate = self.delegate{
                
                delegate.pullUpVC(pullUpViewController: self, didCloseWith: self.rootViewController)
            }
            
            self.originalPullDistance = nil
            self.viewController.removeChild(child: self.rootViewController)
            self.viewController.dismiss(animated: false, completion: completion)
            self.viewController.didDismissController?()
        }
    }
 
    
    @objc private func tapGesturePressed(gesture: UITapGestureRecognizer){
        
        dismiss()
    }
        
    @objc private func panContainer(gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: self.viewController.view)
        
        switch gesture.state {
        case .began:
            
            isPanning = true
            UIView.setAnimationsEnabled(false)
            
        case .changed:
            
            let screenRatio: CGFloat = 0.85
            if let originalPullDistance = originalPullDistance {
                pullUpDistance = originalPullDistance - translation.y
            }
            if pullUpDistance > max(originalPullDistance ?? 0, screenRatio * viewController.view.bounds.height) {
                pullUpDistance = max(originalPullDistance ?? 0, screenRatio * viewController.view.bounds.height)
            }
            
        case .ended, .cancelled, .failed, .possible:
            
            UIView.setAnimationsEnabled(true)
            isPanning = false
            if pullUpDistance < 0.25 * viewController.view.bounds.height {
                dismiss()
            }else {
                if let originalPullDistance = originalPullDistance {
                    self.pullUpDistance = originalPullDistance
                }
                UIView.animate(withDuration: containerPullAnimation) {
                    self.viewController.view.layoutIfNeeded()
                }
            }
            
        @unknown default: break
        }
    }
    
    @objc private func keyboardOpened(_ notification: Notification) {
  
        DispatchQueue.main.async {
            
            guard
                self.expandWithKeyboard,
                !self.keyboardExpanded
                
                else { return
            }
            
            self.keyboardExpanded = true
          
            if let originalPullDistance = self.originalPullDistance {
                self.pullUpDistance = originalPullDistance
            }
        }
    }
    
    @objc private func keyboardClosed(_ notification: Notification) {
                
        DispatchQueue.main.async {
            
            self.keyboardExpanded = false
            
            if self.expandWithKeyboard,
                let originalPullDistance = self.originalPullDistance {
                
                self.pullUpDistance = originalPullDistance
            }
        }
    }
}

fileprivate extension UIViewController {
    
    func addChild(child: UIViewController?, to view: UIView? = nil, boundByConstraint: Bool = false) {
        
        guard
            let child = child,
            let baseView = (view ?? self.view)
            
            else {
                
            print("[UIViewController] Unable to add child View Controller")
            return
        }
        
        addChild(child)
        baseView.addSubview(child.view)
        child.didMove(toParent: self)
        
        if boundByConstraint {
            
            child.view.translatesAutoresizingMaskIntoConstraints = false
            
            child.view.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: 0).isActive = true
            child.view.trailingAnchor.constraint(equalTo: baseView.trailingAnchor, constant: 0).isActive = true
            child.view.topAnchor.constraint(equalTo: baseView.topAnchor, constant: 0).isActive = true
            child.view.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: 0).isActive = true
        }
    }
    
    func removeChild(child: UIViewController?) {
        
        guard
            let child = child
           
            else {
                
            print("[UIViewController] Unable to remove child View Controller")
            return
        }
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
}

extension UIImage {
    
    static let dragIndicatorIcon = UIImage(named: "drag-indicator-icon", in: Bundle(for: FLPullUpViewController.self), compatibleWith: nil)
}
