//
//  DarkScreenView.swift
//  FLPullUpViewController
//
//  Created by Felix Li on 1/12/15.
//  Copyright © 2015 101medialab. All rights reserved.
//

import Foundation

class DarkScreenView: UIView {
    
    var hide = true{
        didSet{
            
                if self.hide{
                    self.alpha = 0
                }else{
                    self.alpha = 0.5
                }
        }
    }
    
    var maskedView = UIView()
    private let topScreen = UIView()
    private let leftScreen = UIView()
    private let rightScreen = UIView()
    private let bottomScreen = UIView()
    
    override init (frame : CGRect) {
        super.init(frame : frame)

    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        
        self.topScreen.backgroundColor = UIColor.blackColor()
        self.leftScreen.backgroundColor = UIColor.blackColor()
        self.rightScreen.backgroundColor = UIColor.blackColor()
        self.bottomScreen.backgroundColor = UIColor.blackColor()
        self.backgroundColor = UIColor.clearColor()


        topScreen.userInteractionEnabled = false
        leftScreen.userInteractionEnabled = false
        rightScreen.userInteractionEnabled = false
        bottomScreen.userInteractionEnabled = false
        
        addSubview(topScreen)
        addSubview(leftScreen)
        addSubview(rightScreen)
        addSubview(bottomScreen)
        
        addSubview(maskedView)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateFrame()
    }
    
    func updateFrame(){
        
        let leadingToRect = self.maskedView.frame.origin.x
        let trailingToRect = bounds.width - self.maskedView.frame.origin.x - self.maskedView.frame.width
        
        self.leftScreen.frame = CGRectMake(0, 0, leadingToRect, self.bounds.height)
        self.rightScreen.frame = CGRectMake(self.maskedView.frame.origin.x + self.maskedView.frame.width , 0, trailingToRect, self.bounds.height)
        self.topScreen.frame = CGRectMake(leadingToRect, 0, self.maskedView.frame.width, self.maskedView.frame.origin.y)
        self.bottomScreen.frame = CGRectMake(self.leftScreen.frame.width, self.maskedView.frame.origin.y + self.maskedView.frame.height , self.maskedView.frame.width, self.bounds.height - self.maskedView.frame.origin.y - self.maskedView.frame.height)
    }
}
