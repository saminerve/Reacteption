//
//  CalculatorClearButton.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 29/04/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import Foundation
import UIKit

class CalculatorClearButton: UIButton {

    let normalStateColor: CGColor! = UIColor(red:0, green:0, blue:0, alpha:0.04).cgColor
    let highlightStateColor: CGColor! = UIColor(red:0, green:0, blue:0, alpha:0.12).cgColor
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        self.setImage(UIImage(named: "buttonClearIconHighlighted.png"), for: .highlighted)
        
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor(cgColor: normalStateColor)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width / 2
    }
    
    override var isHighlighted: Bool {
        
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                let fadeIn = CABasicAnimation(keyPath: "backgroundColor")
                fadeIn.fromValue = normalStateColor
                fadeIn.toValue = highlightStateColor
                fadeIn.duration = 0.12
                fadeIn.autoreverses = false
                fadeIn.repeatCount = 1
                
                self.layer.add(fadeIn, forKey: "fadeIn")
                self.backgroundColor = UIColor(cgColor: highlightStateColor)
            }
            else {
                let fadeOut = CABasicAnimation(keyPath: "backgroundColor")
                fadeOut.fromValue = highlightStateColor
                fadeOut.toValue = normalStateColor
                fadeOut.duration = 0.12
                fadeOut.autoreverses = false
                fadeOut.repeatCount = 1
                
                self.layer.add(fadeOut, forKey: "fadeOut")
                self.backgroundColor = UIColor(cgColor: normalStateColor)
            }
            super.isHighlighted = newValue
        }
    }
    
}
