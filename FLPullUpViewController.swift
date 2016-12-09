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
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
    
    private var originalPullDistance: CGFloat = 0
    private var containerPullAnimation: NSTimeInterval = 0.3
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
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(containerPullAnimation) { () -> Void in
            
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
            
            navVC.navigationBar.frame = CGRectMake(navVC.navigationBar.frame.origin.x, 0, navVC.navigationBar.frame.width, 44)
        }
        
        self.darkScreenView.frame = view.bounds
        
        if self.containerView.frame == CGRectZero{
            
            self.containerView.frame = CGRectMake(containerX, view.bounds.height, containerWidth, view.bounds.height)
            self.rootViewController.view.frame.size.width = containerWidth
            self.darkScreenView.updateFrame()
        }
        
        UIView.animateWithDuration(containerPullAnimation, delay: 0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            
            self.containerView.frame = CGRectMake(containerX, self.view.bounds.height - self.pullUpDistance, containerWidth, self.pullUpDistance)
            self.darkScreenView.updateFrame()
            self.rootViewController.view.frame.size = CGSizeMake(self.containerView.bounds.width, self.pullUpDistance)
            
        }) { (complete) -> Void in
            
            self.blurEffectView.frame = self.containerView.bounds
            self.darkScreenView.backgroundColor = UIColor.clearColor()
        }
    }
    
    func updateBlur(){
        
        blurEffectView.removeFromSuperview()
        rootViewController.view.removeFromSuperview()
        
        if blurBackground{
            
            containerView.backgroundColor = UIColor.clearColor()
            
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
            
            navVC.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            
            navVC.navigationBar.backgroundColor = UIColor.clearColor()
            navVC.view.backgroundColor = UIColor.clearColor()
        }
        
        updateBlur()
        
        modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
    }
    
    // MARK: Button action
    override public func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        
        self.pullUpDistance = 0
        
        UIView.animateWithDuration(containerPullAnimation, animations: { () -> Void in
            
            self.darkScreenView.hide = true
            
        }) { (complete) -> Void in
            
            if (complete){
                
                if let delegate = self.delegate{
                    
                    delegate.pullUpVC(self, didCloseWith: self.rootViewController)
                }
                
                self.rootViewController.view.removeFromSuperview()
                self.rootViewController.dismissViewControllerAnimated(false, completion: nil)
                
                super.dismissViewControllerAnimated(false, completion: completion)
            }
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        darkScreenView.backgroundColor = UIColor.blackColor()
    }
    
    // MARK: Initialization
    private func defaultConfiguration(){
        
        // initial frame to animate from
        darkScreenView.frame = view.bounds
        
        view.clipsToBounds = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panContainer(_:)))
        
        //always fill the view
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        containerView.addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesturePressed(_:)))
        
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
        
        guard let window = UIApplication.sharedApplication().keyWindow,
            var currentVC = window.rootViewController else{
                
                return
        }
        
        while (currentVC.presentedViewController != nil){
            
            if let presentedVC = currentVC.presentedViewController{
                currentVC = presentedVC
            }
        }
        
        containerView.frame = CGRectZero
        
        currentVC.presentViewController(self, animated: false) { () in
            
            if self.pullUpDistance == 0{
                self.pullUpDistance = self.view.bounds.height / 2
            }
        }
    }
    
    public func dismiss(completion: (() -> Void)? = nil){
        
        UIView.setAnimationsEnabled(true)
        
        self.dismissViewControllerAnimated(false, completion: completion)
    }
    
    func tapGesturePressed(gesture: UITapGestureRecognizer){
        
        dismiss()
    }
    
    func panContainer(gesture: UIPanGestureRecognizer){
        
        let translation = gesture.translationInView(self.view)
        
        if gesture.state == .Began{
            
            UIView.setAnimationsEnabled(false)
            
            originalPullDistance = pullUpDistance
            
        }else if gesture.state == .Changed{
            
            let screenRatio: CGFloat = 0.85
            
            pullUpDistance = originalPullDistance - translation.y
            
            if pullUpDistance > screenRatio * view.bounds.height{
                
                pullUpDistance = screenRatio * view.bounds.height
            }
            
        }else if gesture.state == .Ended || gesture.state == .Cancelled || gesture.state == .Failed{
            
            UIView.setAnimationsEnabled(true)
            if pullUpDistance < 0.25 * view.bounds.height{
                dismiss()
            }else{
                pullUpDistance = originalPullDistance
            }
        }
    }
}
