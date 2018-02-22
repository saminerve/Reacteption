//
//  CoinViewControllers.swift
//  Currency
//
//  Created by SMA5236 on 22/02/2018.
//  Copyright © 2018 Nuno Coelho Santos. All rights reserved.
//

import Foundation
import UIKit
import React

class CoinViewController: UIViewController {
    
    
    @IBOutlet weak var container: UIView!
    
    override func viewDidLoad() {
        let jsCodeLocation = URL(string: "http://localhost:8081/index.bundle?platform=ios")
        
        guard let rootView = RCTRootView(
            bundleURL: jsCodeLocation,
            moduleName: "CurrencyInformationsComponent",
            initialProperties: nil,
            launchOptions: nil
            ) else {
            return
        }
        
        rootView.frame = CGRect(origin: CGPoint.zero, size: self.container.frame.size)
        
        self.container.addSubview(rootView)
    }
}
