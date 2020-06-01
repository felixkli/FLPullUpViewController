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
extension PullUpDelegate {
    
    func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController){
        
    }
}

public class FLPullUpViewController: UIViewController {
    
    private static let pullBarHeight: CGFloat = 20
//    private static let navBarHeight: CGFloat = 20

    private var rootViewController: UIViewController = UIViewController() {
        didSet{
            self.removeChild(child: oldValue)
            self.setupPullUpVC()
        }
    }
    
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var darkScreenView = DarkScreenView()
    private var containerView = UIView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    private var isPanning = false
    
    private var originalPullDistance: CGFloat? = nil
    private var containerPullAnimation: TimeInterval = 0.3
    
    private var keyboardExpanded: Bool = false
        
    lazy private var pullTabImageView: UIImageView = {
        
        let imageView = UIImageView(image: UIImage(named: "close-icon", in: Bundle(for: Self), compatibleWith: nil))
        return imageView
    }()
    
    public weak var delegate: PullUpDelegate?
    
    public var pullToClose: Bool = true {
        didSet{
            if pullToClose, let panGesture = panGesture {
                
                containerView.addGestureRecognizer(panGesture)
                
            }else if containerView.gestureRecognizers?.contains(panGesture) == true{
                
                containerView.removeGestureRecognizer(panGesture)
            }
        }
    }
    
    public var compressViewForLargeScreens = false
    public var maxWidthForCompressedView: CGFloat = 700
    public var setBlackBorder: Bool = false {
        didSet{
            if setBlackBorder {
                containerView.layer.borderColor = UIColor.black.cgColor
                containerView.layer.borderWidth = 1
            }else{
                containerView.layer.borderColor = UIColor.black.cgColor
                containerView.layer.borderWidth = 0
            }
        }
    }

    
    public var blurBackground = true{
        didSet{
            
            updateBlur()
        }
    }
    
    public var pullUpDistance: CGFloat = 0{
        didSet{
            
            if originalPullDistance == nil {
                self.originalPullDistance = self.pullUpDistance
            }
            
            view.setNeedsLayout()
        }
    }
    
    public var showPullUpBar: Bool = false {
        didSet{
            
            view.setNeedsLayout()
        }
    }
        
    public var expandWithKeyboard: Bool = false
    
    public init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(rootViewController: UIViewController) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.rootViewController = rootViewController
        
        //        setupPullUpVC()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Life Cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        defaultConfiguration()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: containerPullAnimation) {
            
            self.darkScreenView.hide = false
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var containerX: CGFloat = 0
        var containerWidth: CGFloat = view.bounds.width
        
        if compressViewForLargeScreens{
            containerWidth =  min(view.bounds.width, maxWidthForCompressedView)
            containerX = (view.bounds.width - containerWidth) / 2
        }
        
        if let navVC = rootViewController as? UINavigationController{
            
            navVC.navigationBar.frame = CGRect(x: navVC.navigationBar.frame.origin.x, y: 0, width: navVC.navigationBar.frame.width, height: 44)
        }
        
        self.darkScreenView.frame = view.bounds
        
        if self.containerView.frame == CGRect.zero {
            
            self.containerView.frame = CGRect(x: containerX, y: view.bounds.height, width: containerWidth, height: view.bounds.height)
            self.darkScreenView.updateFrame()
        }
        
        UIView.animate(withDuration: containerPullAnimation, delay: 0, options: [.beginFromCurrentState], animations: {
            
            self.containerView.frame.origin = CGPoint(x: containerX, y: self.view.frame.height - self.pullUpDistance)
            self.containerView.frame.size = CGSize(width: containerWidth, height: max(self.pullUpDistance, (self.originalPullDistance ?? 0)))
            
            let pullBarHeight = (self.showPullUpBar)
                ? Self.pullBarHeight
                : 0
            
            if #available(iOS 11.0, *) {
                self.rootViewController.additionalSafeAreaInsets = UIEdgeInsets(top: pullBarHeight, left: 0, bottom: 0, right: 0)
            }
            
            print("[pull] self.containerView.bounds.width: \(self.containerView.bounds.width)")
            print("[pull] rootViewController: \(self.rootViewController.view.bounds.width)")
            print("[pull] childView: \((self.rootViewController as? UINavigationController)?.viewControllers.first?.view.bounds.width)")
            
            // Setting rootViewController as frame
            self.rootViewController.view.frame = CGRect(x: 0, y: 0, width: self.containerView.bounds.width, height: self.containerView.frame.height)
                        
            self.darkScreenView.updateFrame()
            
        }) { (complete) -> Void in
            
            if self.showPullUpBar {
                
                self.pullTabImageView.frame = CGRect(x: (self.containerView.bounds.width - self.pullTabImageView.bounds.width) / 2,
                                                     y: (Self.pullBarHeight - self.pullTabImageView.bounds.height) / 2 + 5,
                                                     width: self.pullTabImageView.bounds.width,
                                                     height: self.pullTabImageView.bounds.height)
                
                self.containerView.addSubview(self.pullTabImageView)
            }else{
                
                self.pullTabImageView.removeFromSuperview()
            }
            
            self.blurEffectView.frame = self.containerView.bounds
            self.darkScreenView.backgroundColor = UIColor.clear
        }
    }
    
    func updateBlur(){
        
        blurEffectView.removeFromSuperview()
        removeChild(child: rootViewController)
        
        if blurBackground{
            
            containerView.backgroundColor = UIColor.clear
            
            containerView.addSubview(blurEffectView)
            
            self.addChild(child: rootViewController, to: blurEffectView)
        }else{
            
//            containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            containerView.backgroundColor = .white
            
            self.addChild(child: rootViewController, to: containerView)
        }
    }
    
//    func updatePullUpDistance(_ distance: CGFloat) {
//
//        self.originalPullDistance = distance
//        self.pullUpDistance = distance
//
//        view.setNeedsLayout()
//    }
    
    // MARK: Update appearance
    
    func setupPullUpVC(){
        
        if let navVC = rootViewController as? UINavigationController,
            let displayingVC = navVC.viewControllers.first{
            
            displayingVC.automaticallyAdjustsScrollViewInsets = false
            
            navVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
            
            navVC.navigationBar.backgroundColor = UIColor.clear
            navVC.view.backgroundColor = UIColor.clear
        }
        
        updateBlur()
        
        modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    // MARK: Button action
    override public func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        
//        self.tempPullHeight = self.pullUpDistance
        self.pullUpDistance = 0
        
        UIView.animate(withDuration: containerPullAnimation, animations: { () -> Void in
            
            self.darkScreenView.hide = true
            
        }) { (complete) -> Void in
            
            if (complete){
                
                if let delegate = self.delegate{
                    
                    delegate.pullUpVC(pullUpViewController: self, didCloseWith: self.rootViewController)
                }
                
                self.removeChild(child: self.rootViewController)
                self.rootViewController.dismiss(animated: false, completion: nil)
                
//                self.tempPullHeight = nil
                self.originalPullDistance = nil
                
                super.dismiss(animated: false, completion: completion)
            }
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        darkScreenView.backgroundColor = UIColor.black
    }
    
    // MARK: Initialization
    private func defaultConfiguration(){
        
        // initial frame to animate from
        darkScreenView.frame = view.bounds
        
        view.clipsToBounds = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panContainer(gesture:)))
        
        //always fill the view
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardOpened(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardClosed(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        if pullToClose {
            containerView.addGestureRecognizer(panGesture)
        }
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesturePressed(gesture:)))
        
        darkScreenView.addGestureRecognizer(tapGesture)
        
        darkScreenView.hide = true
        
        darkScreenView.maskedView = containerView
        
        setupPullUpVC()
        
        updateBlur()
        
        view.addSubview(darkScreenView)
        view.addSubview(containerView)
    }
    
    //MARK: Setter
    
    public func setRootViewController(rootViewController: UIViewController){
        
        self.rootViewController = rootViewController
    }
    
    // MARK: Present pullUpVC
    //  .presentViewController does not check for UINavigationController, UIPageViewController cases
    public func show(){
        
        /* Prevent Error:
         
         Fatal Exception: NSInvalidArgumentException
         Application tried to present modally an active controller
         
         */
        
        guard
            self.presentingViewController == nil,
            let window = UIApplication.shared.keyWindow,
            var currentVC = window.rootViewController else{
                
                return
        }
        
        while (currentVC.presentedViewController != nil){
            
            if let presentedVC = currentVC.presentedViewController{
                currentVC = presentedVC
            }
        }
        
        containerView.frame = CGRect.zero
        
        currentVC.present(self, animated: false) {
            
            if self.pullUpDistance == 0 {
                self.pullUpDistance = self.view.bounds.height / 2
            }
        }
    }
    
    public func dismiss(completion: (() -> Void)? = nil){
        
        UIView.setAnimationsEnabled(true)
        
        self.dismiss(animated: false, completion: completion)
    }
    
    @objc func tapGesturePressed(gesture: UITapGestureRecognizer){
        
        dismiss()
    }
    
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
    }
    
    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
           
    }
    
    @objc func panContainer(gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: self.view)
        
        switch gesture.state {
        case .began:
            
            isPanning = true
            UIView.setAnimationsEnabled(false)
            
            originalPullDistance = pullUpDistance
            
        case .changed:
            let screenRatio: CGFloat = 0.85
            
            if let originalPullDistance = originalPullDistance {
                pullUpDistance = originalPullDistance - translation.y
            }
            
            if pullUpDistance > max(originalPullDistance ?? 0, screenRatio * view.bounds.height) {
                
                pullUpDistance = max(originalPullDistance ?? 0, screenRatio * view.bounds.height)
            }
            
        case .ended, .cancelled, .failed, .possible:
            
            isPanning = false
            
            UIView.setAnimationsEnabled(true)
            
            if pullUpDistance < 0.25 * view.bounds.height{
                dismiss()
            }else{
                
                if let originalPullDistance = originalPullDistance {
                    self.pullUpDistance = originalPullDistance
                }
                
                UIView.animate(withDuration: containerPullAnimation) {
                    
                    self.view.layoutIfNeeded()
                }
            }
            
        @unknown default: break
        }
    }
    
    @objc func keyboardOpened(_ notification: Notification) {
  
        DispatchQueue.main.async {
            
            guard
                self.expandWithKeyboard,
                !self.keyboardExpanded
                
                else { return
            }
            
            self.keyboardExpanded = true
            
            if self.originalPullDistance == nil {
                self.originalPullDistance = self.pullUpDistance
            }
            
            if let originalPullDistance = self.originalPullDistance{
            
                self.pullUpDistance = originalPullDistance + 100
            }
        }
    }
    
    @objc func keyboardClosed(_ notification: Notification) {
        
        print("[pull] keyboard close")
        
        DispatchQueue.main.async {
            
            if self.expandWithKeyboard,
                let originalPullDistance = self.originalPullDistance {
                
                self.pullUpDistance = originalPullDistance
            }
            
            self.keyboardExpanded = false
        }
    }
    
    deinit {
        print("[deinit] FLPullViewController: \(rootViewController)")
        NotificationCenter.default.removeObserver(self)
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
