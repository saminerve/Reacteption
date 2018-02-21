//
//  CurrencyButton.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 19/05/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import Foundation
import UIKit

class CurrencyButton: UIButton {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = 1
                fadeOut.toValue = 0.3
                fadeOut.duration = 0.03
                fadeOut.autoreverses = false
                fadeOut.repeatCount = 1
                
                self.layer.add(fadeOut, forKey: "fadeOut")
                self.layer.opacity = 0.3
            }
            else {
                let fadeIn = CABasicAnimation(keyPath: "opacity")
                fadeIn.fromValue = 0.3
                fadeIn.toValue = 1
                fadeIn.duration = 0.12
                fadeIn.autoreverses = false
                fadeIn.repeatCount = 1
                
                self.layer.add(fadeIn, forKey: "fadeIn")
                self.layer.opacity = 1
            }
            super.isHighlighted = newValue
        }
    }
    
}
