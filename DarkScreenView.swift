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
//    private let leftScreen = UIView()
//    private let rightScreen = UIView()
//    private let bottomScreen = UIView()
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        
        self.topScreen.backgroundColor = UIColor.black
//        self.leftScreen.backgroundColor = UIColor.black
//        self.rightScreen.backgroundColor = UIColor.black
//        self.bottomScreen.backgroundColor = UIColor.black
        self.backgroundColor = UIColor.clear
        
        
        topScreen.isUserInteractionEnabled = false
//        leftScreen.isUserInteractionEnabled = false
//        rightScreen.isUserInteractionEnabled = false
//        bottomScreen.isUserInteractionEnabled = false
        
        addSubview(topScreen)
//        addSubview(leftScreen)
//        addSubview(rightScreen)
//        addSubview(bottomScreen)
        
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
        
//        let leadingToRect = self.maskedView.frame.origin.x
//        let trailingToRect = bounds.width - self.maskedView.frame.origin.x - self.maskedView.frame.width
        
        self.topScreen.frame = self.bounds
        
//        self.leftScreen.frame = CGRect(x: 0, y: 0, width: leadingToRect, height: self.bounds.height)
//        self.rightScreen.frame = CGRect(x: self.maskedView.frame.origin.x + self.maskedView.frame.width, y: 0, width: trailingToRect, height: self.bounds.height)
//        self.topScreen.frame = CGRect(x: leadingToRect, y: 0, width: self.maskedView.frame.width, height: self.maskedView.frame.origin.y)
//        self.bottomScreen.frame = CGRect(x:self.leftScreen.frame.width, y: self.maskedView.frame.origin.y + self.maskedView.frame.height , width: self.maskedView.frame.width, height: self.bounds.height - self.maskedView.frame.origin.y - self.maskedView.frame.height)
    }
}
