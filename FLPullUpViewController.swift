//
//  FLPullUpViewController.swift
//  FLPullUpViewController
//
//  Created by Felix Li on 1/12/15.
//  Copyright © 2015 101medialab. All rights reserved.
//

import Foundation

public protocol PullUpDelegate: class{
    
    func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController)
}

// OPTIONAL
extension PullUpDelegate{
    
    func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController){
        
    }
}

public class FLPullUpViewController: UIViewController {
    
    private var rootViewController: UIViewController = UIViewController(){
        
        didSet{
            
            oldValue.view.removeFromSuperview()
            
            setupPullUpVC()
        }
    }
    
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var darkScreenView = DarkScreenView()
    private var containerView = UIView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    private var originalPullDistance: CGFloat = 0
    private var containerPullAnimation: TimeInterval = 0.3
    private var navBarHeight: CGFloat = 0
    
    public weak var delegate: PullUpDelegate?
    
    public var compressViewForLargeScreens = false
    public var maxWidthForCompressedView: CGFloat = 700
    
    public var blurBackground = true{
        didSet{
            
            updateBlur()
        }
    }
    
    public var pullUpDistance: CGFloat = 0{
        didSet{
            view.setNeedsLayout()
        }
    }
    
    public init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(rootViewController: UIViewController) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.rootViewController = rootViewController
        
        setupPullUpVC()
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
        
        UIView.animate(withDuration: containerPullAnimation) { () -> Void in
            
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
        
        if self.containerView.frame == CGRect.zero{
            
            self.containerView.frame = CGRect(x: containerX, y: view.bounds.height, width: containerWidth, height: view.bounds.height)
            self.rootViewController.view.frame.size.width = containerWidth
            self.darkScreenView.updateFrame()
        }
        
        UIView.animate(withDuration: containerPullAnimation, delay: 0, options: [.beginFromCurrentState], animations: {
            
            self.containerView.frame = CGRect(x: containerX, y: self.view.bounds.height - self.pullUpDistance, width: containerWidth, height: self.pullUpDistance)
            self.darkScreenView.updateFrame()
            self.rootViewController.view.frame.size = CGSize(width: self.containerView.bounds.width, height: self.pullUpDistance)
            
        }) { (complete) -> Void in
            
            self.blurEffectView.frame = self.containerView.bounds
            self.darkScreenView.backgroundColor = UIColor.clear
        }
    }
    
    func updateBlur(){
        
        blurEffectView.removeFromSuperview()
        rootViewController.view.removeFromSuperview()
        
        if blurBackground{
            
            containerView.backgroundColor = UIColor.clear
            
            containerView.addSubview(blurEffectView)
            blurEffectView.addSubview(rootViewController.view)
        }else{
            
            containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            
            containerView.addSubview(rootViewController.view)
        }
    }
    
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
        
        self.pullUpDistance = 0
        
        UIView.animate(withDuration: containerPullAnimation, animations: { () -> Void in
            
            self.darkScreenView.hide = true
            
        }) { (complete) -> Void in
            
            if (complete){
                
                if let delegate = self.delegate{
                    
                    delegate.pullUpVC(pullUpViewController: self, didCloseWith: self.rootViewController)
                }
                
                self.rootViewController.view.removeFromSuperview()
                self.rootViewController.dismiss(animated: false, completion: nil)
                
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
        
        containerView.addGestureRecognizer(panGesture)
        
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
        
        guard let window = UIApplication.shared.keyWindow,
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
            
            if self.pullUpDistance == 0{
                self.pullUpDistance = self.view.bounds.height / 2
            }
        }
    }
    
    public func dismiss(completion: (() -> Void)? = nil){
        
        UIView.setAnimationsEnabled(true)
        
        self.dismiss(animated: false, completion: completion)
    }
    
    func tapGesturePressed(gesture: UITapGestureRecognizer){
        
        dismiss()
    }
    
    func panContainer(gesture: UIPanGestureRecognizer){
        
        let translation = gesture.translation(in: self.view)
        
        if gesture.state == .began{
            
            UIView.setAnimationsEnabled(false)
            
            originalPullDistance = pullUpDistance
            
        }else if gesture.state == .changed{
            
            let screenRatio: CGFloat = 0.85
            
            pullUpDistance = originalPullDistance - translation.y
            
            if pullUpDistance > screenRatio * view.bounds.height{
                
                pullUpDistance = screenRatio * view.bounds.height
            }
            
        }else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed{
            
            UIView.setAnimationsEnabled(true)
            if pullUpDistance < 0.25 * view.bounds.height{
                dismiss()
            }else{
                pullUpDistance = originalPullDistance
            }
        }
    }
}
