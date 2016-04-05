import Foundation

@objc public protocol PullUpDelegate{
    
    optional func pullUpVC(pullUpViewController: FLPullUpViewController, didCloseWith rootViewController:UIViewController)
}

public class FLPullUpViewController: UIViewController {
    
    private var rootViewController: UIViewController!{
        
        didSet{
            if let oldVC = oldValue{
                oldVC.view.removeFromSuperview()
            }
            
            if rootViewController is UINavigationController{
                let navVC = rootViewController as? UINavigationController
                navVC?.viewControllers.first?.automaticallyAdjustsScrollViewInsets = false
            }
            
            if let newVC = rootViewController{
                blurEffectView.addSubview(newVC.view)
            }
            
            modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
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
    
    public var pullUpDistance: CGFloat = 0{
        didSet{
            view.setNeedsLayout()
        }
    }
    
    public init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(rootViewController: UIViewController) {
        
        self.rootViewController = rootViewController
        
        super.init(nibName: nil, bundle: nil)
        
        if rootViewController is UINavigationController{
            let navVC = rootViewController as? UINavigationController
            navVC?.viewControllers.first?.automaticallyAdjustsScrollViewInsets = false
        }
        
        blurEffectView.addSubview(self.rootViewController.view)
        
        modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
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
        
        UIView.animateWithDuration(0.3) { () -> Void in
            
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
        
        self.darkScreenView.frame = view.bounds
        
        if self.containerView.frame == CGRectZero{
            self.containerView.frame = CGRectMake(containerX, view.bounds.height, containerWidth, view.bounds.height)
            self.darkScreenView.updateFrame()
        }
        
        self.rootViewController.view.frame.size = CGSizeMake(containerWidth, view.bounds.height)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.containerView.frame = CGRectMake(
                containerX,
                self.view.bounds.height - self.pullUpDistance,
                containerWidth,
                self.view.bounds.height)
            
            self.darkScreenView.updateFrame()
            
        }) { (complete) -> Void in
            self.blurEffectView.frame = self.containerView.bounds
            self.rootViewController.view.frame.size = CGSizeMake(self.containerView.bounds.width, self.pullUpDistance)
            self.darkScreenView.backgroundColor = UIColor.clearColor()
        }
    }
    
    // MARK: Button action
    override public func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        
        pullUpDistance = 0
        
        UIView.animateWithDuration(0.3, animations: {[weak self] () -> Void in
            
            self?.darkScreenView.hide = true
            
        }) { (complete) -> Void in
            if (complete){
                if let delegate = self.delegate{
                    delegate.pullUpVC!(self, didCloseWith: self.rootViewController)
                }
                
                if let vc = self.rootViewController{
                    vc.view.removeFromSuperview()
                }
                
                super.dismissViewControllerAnimated(false, completion: completion)
            }
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        darkScreenView.backgroundColor = UIColor.blackColor()
    }
    
    // MARK: Initialization
    func defaultConfiguration(){
        
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
        
        containerView.addSubview(blurEffectView)
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
        
        var currentVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        
        while (currentVC?.presentedViewController != nil){
            currentVC = currentVC?.presentedViewController
        }
        
        currentVC!.presentViewController(self, animated: false) { () -> Void in
            if self.pullUpDistance == 0{
                self.pullUpDistance = self.view.bounds.height / 2
            }
        }
    }
    
    public func dismiss(completion: (() -> Void)? = nil){
        
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
            
        }else if gesture.state == .Ended || gesture.state == .Cancelled{
            
            UIView.setAnimationsEnabled(true)
            if pullUpDistance < 0.25 * view.bounds.height{
                dismiss()
            }else{
                pullUpDistance = originalPullDistance
            }
        }
    }
}
