//
//  Calculator.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 11/03/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import Foundation

class Calculator {
    
    var initialValue: Double
    var operationSymbol: String?
    var operationInProgress: Bool
    var settingNewValue: Bool
    
    init() {
        initialValue = 0
        operationSymbol = nil
        operationInProgress = false
        settingNewValue = false
    }
    
    func calculate(_ number:Double) -> Double {
        if settingNewValue {
            let result = initialValue
            reset()
            return result
        }
        if operationInProgress {
            var result:Double = initialValue
            if operationSymbol == "+" {
                result = initialValue + number
            }
            if operationSymbol == "-" {
                result = initialValue - number
            }
            reset()
            initialValue = result
            return result
        }
        reset()
        return number
    }
    
    func newAddition(_ number: Double) {
        initialValue = calculate(number)
        operationSymbol = "+"
        settingNewValue = true
        operationInProgress = true
    }
    
    func newSubtraction(_ number: Double) {
        initialValue = calculate(number)
        operationSymbol = "-"
        settingNewValue = true
        operationInProgress = true
    }
    
    func reset() {
        initialValue = 0
        operationSymbol = nil
        settingNewValue = false
        operationInProgress = false
    }
    
}
