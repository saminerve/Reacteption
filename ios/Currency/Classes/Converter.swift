//
//  Converter.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 26/02/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import Foundation
import CoreData
import SWXMLHash

class Converter {

    var input:(integer: String, decimal: String, decimalMode: Bool, decimalInputs: Int)
    var inputCurrency: Coin
    var outputCurrency: Coin

    init() {
        input.integer = "0"
        input.decimal = ""
        input.decimalMode = false
        input.decimalInputs = 0

        inputCurrency = Coin(withCode: "JPY", update: false, remember: false)
        outputCurrency = Coin(withCode: "GBP", update: false, remember: false)
    }

    // MARK: Convert.

    func convertToInputCurrency(_ number: Double) -> Double {
        let result: Double = (number / outputCurrency.rate) * inputCurrency.rate
        return result
    }

    func convertToOutputCurrency(_ number: Double) -> Double {
        let result: Double = (number / inputCurrency.rate) * outputCurrency.rate
        return result
    }

    // MARK: Format as currency.

    func parsedInput() -> Double {
        var inputString: String
        if let integer = Int(input.integer) {
            inputString = "\(integer)"
        } else {
            inputString = "0"
        }
        if !input.decimal.isEmpty {
            inputString = inputString + "." + "\(input.decimal)"
        }
        return Double(inputString)!
    }

    func formattedInput() -> String {
        let inputValue: Double! = parsedInput()
        print("Input value:", inputValue)
        let formattedInput = formatToCurrency(
                inputValue,
                code: inputCurrency.code,
                locale: inputCurrency.locale,
                symbol: inputCurrency.symbol,
                decimals: inputCurrency.decimals,
                symbolPosition: inputCurrency.symbolPosition,
                useLocalization: inputCurrency.useLocalization,
                useSymbol: inputCurrency.useSymbol,
                useCustomSymbol: inputCurrency.useCustomSymbol
            )
        return formattedInput
    }

    func formattedOutput() -> String {
        let inputValue: Double! = parsedInput()
        let outputValue: Double = convertToOutputCurrency(inputValue)
        print("Output value:", outputValue)
        let formattedOutput = formatToCurrency(
                outputValue,
                code: outputCurrency.code,
                locale: outputCurrency.locale,
                symbol: outputCurrency.symbol,
                decimals: outputCurrency.decimals,
                symbolPosition: outputCurrency.symbolPosition,
                useLocalization: outputCurrency.useLocalization,
                useSymbol: outputCurrency.useSymbol,
                useCustomSymbol: outputCurrency.useCustomSymbol
            )
        return formattedOutput
    }

    fileprivate func formatToCurrency(
                _ value: Double,
                code: String,
                locale: String?,
                symbol: String?,
                decimals: Int,
                symbolPosition: String?,
                useLocalization: Bool,
                useSymbol: Bool,
                useCustomSymbol: Bool
            ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.usesGroupingSeparator = true;
        formatter.groupingSeparator = ","
        
        if useLocalization {
            if let locale = locale, !locale.isEmpty {
                formatter.locale = Locale(identifier: locale)
            }
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        
        if useSymbol {
            if useCustomSymbol {
                if let symbol = symbol, !symbol.isEmpty {
                    formatter.currencySymbol = symbol
                }
            }
        } else {
            formatter.currencySymbol = ""
        }
        
        var offset = 0
        if symbolPosition == "right" && useSymbol {
            if let symbol = symbol, !symbol.isEmpty {
                offset = symbol.characters.count
            }
        }
        
        var formattedCurrency: String! = formatter.string(from: NSNumber(value: value))

        if code == inputCurrency.code {
            formattedCurrency = truncateDecimalsToDecimalInputLength(formattedCurrency, decimals: decimals, offset: offset)
        } else {
            formattedCurrency = truncateEmptyDecimalsFromCurrency(formattedCurrency, decimals: decimals, offset: offset)
        }

        return formattedCurrency!
    }

    fileprivate func truncateDecimalsToDecimalInputLength(_ formattedCurrency: String, decimals: Int, offset: Int) -> String {
        guard decimals > 0 else {
            print("No decimals to truncate from price string")
            return formattedCurrency
        }

        let truncationLenght: Int! = (input.decimalMode ? decimals : decimals + 1) - input.decimalInputs

        guard truncationLenght > 0 else {
            print("Truncation length is a negative value");
            return formattedCurrency
        }

        let symbol: String! = String(formattedCurrency.characters.dropFirst(formattedCurrency.characters.count - offset))
        let number: String! = String(formattedCurrency.characters.dropLast(offset)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let truncatedNumber: String! = String(number.characters.dropLast(truncationLenght))
        let truncatedPrice: String! = truncatedNumber + symbol

        return truncatedPrice
    }

    fileprivate func truncateEmptyDecimalsFromCurrency(_ formattedCurrency: String, decimals: Int, offset: Int) -> String {
        guard decimals > 0 else {
            print ("There are no decimals to truncate from this currency")
            return formattedCurrency
        }
        
        let truncationLenght: Int! = decimals + 1
        let symbol: String! = String(formattedCurrency.characters.dropFirst(formattedCurrency.characters.count - offset))
        let number: String! = String(formattedCurrency.characters.dropLast(offset)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let lastCharacters: String! = String(number.characters.suffix(truncationLenght))
        let decimalDivider: String! = String(lastCharacters.characters.prefix(1))
        let emptyDecimals = decimalDivider + String(repeating: "0", count: decimals)
    
        if (lastCharacters == emptyDecimals) {
            let truncatedNumber: String! = String(number.characters.dropLast(truncationLenght))
            let truncatedPrice: String! = truncatedNumber + symbol
            return truncatedPrice
        } else {
            return formattedCurrency
        }
    }

    // MARK: Add input.

    func addInput(_ newInput: String) {

        if input.decimalMode {
            addDecimalInput(newInput)
        } else {
            addIntegerInput(newInput)
        }

    }

    fileprivate func addIntegerInput(_ newInput: String) {
        guard input.integer.characters.count < 8 else {
            print("Input string is too long.")
            return
        }
        if input.integer == "0" && newInput == "0" {
            print("Value string is already zero or empty.")
            return
        }
        if input.integer == "0" && newInput != "0" {
            input.integer = newInput
            return
        }

        input.integer = input.integer + newInput
    }

    fileprivate func addDecimalInput(_ newInput: String) {
        print("Adding decimal input: \(newInput).")
        guard input.decimal.characters.count < inputCurrency.decimals else {
            print("Decimal input string has already reached the maximum length.")
            return
        }

        input.decimal = input.decimal + newInput
        print("New decimal input is: \(input.decimal)")
        input.decimalInputs = input.decimalInputs + 1
        print("New number of decimal inputs so far is: \(input.decimalInputs).")
    }

    // MARK: Remove input.

    func removeLastInput() {
        if input.decimalMode && inputCurrency.decimals > 0 {
            if input.decimal.isEmpty {
                input.decimalMode = false
            } else {
                removeLastDecimalInput()
            }
        } else {
            removeLastIntegerInput()
        }
    }

    fileprivate func removeLastIntegerInput() {
        if input.integer == "0" {
            print("Input integer value string is already zero.")
            return
        }
        if input.integer.characters.count == 1 {
            input.integer = "0"
            print("Input integer value was set to zero because it was a single digit value.")
            return
        }
        input.integer = String(input.integer.characters.dropLast())
    }

    fileprivate func removeLastDecimalInput() {
        guard !input.decimal.isEmpty else {
            print("Input decimal value is already empty.")
            return
        }
        input.decimal = String(input.decimal.characters.dropLast())
        input.decimalInputs = input.decimalInputs - 1
    }

    // MARK: Swap input with output.

    func setInputValue(_ value: Double) {
        // First split the double into an integer and decimal string.
        let valueInteger: String = String(value.split()[0])
        let valueDecimal: String = String(value.split()[1])
        // Then define the values to be set.
        let newInteger: String = valueInteger
        let newDecimal: String = valueDecimal == "0" ? "" : valueDecimal
        let newNumberOfDecimalInputs: Int! = newDecimal.characters.count
        let isDecimalModeOn: Bool! = newNumberOfDecimalInputs == 0 ? false : true
        // Finally, set the values.
        input.integer = newInteger
        input.decimal = newDecimal
        input.decimalInputs = newNumberOfDecimalInputs
        input.decimalMode = isDecimalModeOn
    }

    func swapInputWithOutput(convertInputValue: Bool = true) {
        if convertInputValue {
            // First let's get the values from the output currency.
            let oldOutput = parseCurrency(
                    formattedOutput(),
                    code: outputCurrency.code,
                    locale: outputCurrency.locale,
                    symbol: outputCurrency.symbol,
                    decimals: outputCurrency.decimals,
                    symbolPosition: outputCurrency.symbolPosition,
                    useLocalization: outputCurrency.useLocalization,
                    useSymbol: outputCurrency.useSymbol,
                    useCustomSymbol: outputCurrency.useCustomSymbol
                )
            // Then set those values as the new input.
            setInputValue(oldOutput)
            // And finally, swap the currencies.
        }
        let newInputCurrencyCode = outputCurrency.code
        let newOutputCurrencyCode = inputCurrency.code
        inputCurrency.setTo(newInputCurrencyCode!, update: false, remember: false)
        outputCurrency.setTo(newOutputCurrencyCode!, update: false, remember: false)

    }

    fileprivate func parseCurrency(
                _ formattedCurrency: String,
                code: String,
                locale: String?,
                symbol: String?,
                decimals: Int,
                symbolPosition: String?,
                useLocalization: Bool,
                useSymbol: Bool,
                useCustomSymbol: Bool
            ) -> Double {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.usesGroupingSeparator = true;
        formatter.groupingSeparator = ","
        
        if useLocalization {
            if let locale = locale, !locale.isEmpty {
                formatter.locale = Locale(identifier: locale)
            }
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        
        if useSymbol {
            if useCustomSymbol {
                if let symbol = symbol, !symbol.isEmpty {
                    formatter.currencySymbol = symbol
                }
            }
        } else {
            formatter.currencySymbol = ""
        }
        
        if let number = formatter.number(from: formattedCurrency) {
            return (number.doubleValue)
        } else {
            print("Could not parse double from formatted currency string.")
            return 0.0
        }

    }

    // MARK: Reset.

    func clear() {
        input.integer = "0"
        input.decimal = ""
        input.decimalMode = false
        input.decimalInputs = 0
    }

    func beginDecimalInput() {
        guard inputCurrency.decimals != 0 else {
            print("Input currency does not have decimals")
            return
        }
        input.decimal = ""
        input.decimalMode = true
        input.decimalInputs = 0
        print("Started inputting decimals.")
    }
    
    // MARK: Update multiple rates.
    
    func updateCurrentCurrencies() {
        
        let currentInputCurrency = inputCurrency.code
        let currentOutputCurrency = outputCurrency.code
        
        func showActivityIndicator() {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateActivityIndicator"), object: nil, userInfo: ["currencyCode": currentInputCurrency, "action": "show"])
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateActivityIndicator"), object: nil, userInfo: ["currencyCode": currentOutputCurrency, "action": "show"])
        }
        
        func hideActivityIndicator() {
            // Update UI on main thread.
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateActivityIndicator"), object: nil, userInfo: ["currencyCode": currentInputCurrency, "action": "hide"])
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateActivityIndicator"), object: nil, userInfo: ["currencyCode": currentOutputCurrency, "action": "hide"])
            }
        }
        
        // Start by showing the network indicator.
        showActivityIndicator()
        
        let url = URL(string: "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USD" + currentInputCurrency! + "%2CUSD" + currentOutputCurrency! + "%22)&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys")
        
        let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            
            guard data != nil else {
                print("Error performing Yahoo query when updating current currencies.")
                hideActivityIndicator()
                return
            }
            
            var fetchedInputRate: String
            var fetchedOutputRate: String
            let xml = SWXMLHash.parse(data!)
            
            do {
                fetchedInputRate = try xml["query"]["results"]["rate"].withAttribute("id", "USD" + currentInputCurrency!)["Rate"].element!.text
                fetchedOutputRate = try xml["query"]["results"]["rate"].withAttribute("id", "USD" + currentOutputCurrency!)["Rate"].element!.text
            } catch {
                print("Error fetching currencies: \(error)")
                hideActivityIndicator()
                return
            }
            
            // Hide the network indicator.
            hideActivityIndicator()
            
            // Update UI on main thread.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "CoinUpdatedNotification"), object: nil, userInfo: ["currencyCode": currentInputCurrency!, "currencyRate": fetchedInputRate])
                NotificationCenter.default.post(name: Notification.Name(rawValue: "CoinUpdatedNotification"), object: nil, userInfo: ["currencyCode": currentOutputCurrency!, "currencyRate": fetchedOutputRate])
                print("Updated input and output currency rates.")
            }
            
            // CoreData setup.
            let managedObjectContext: NSManagedObjectContext!
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            managedObjectContext = appDelegate.managedObjectContext as NSManagedObjectContext
            var inputCurrencyRecord: Currency
            var outputCurrencyRecord: Currency
            
            // CoreData fetching.
            let inputFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
            let inputPredicate = NSPredicate(format: "%K == %@", "code", currentInputCurrency!)
            inputFetch.predicate = inputPredicate
            inputFetch.fetchLimit = 2
            let outputFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
            let outputPredicate = NSPredicate(format: "%K == %@", "code", currentOutputCurrency!)
            outputFetch.predicate = outputPredicate
            outputFetch.fetchLimit = 1
            
            do {
                inputCurrencyRecord = try managedObjectContext.fetch(inputFetch).first as! Currency
                outputCurrencyRecord = try managedObjectContext.fetch(outputFetch).first as! Currency
            } catch {
                print("Error fetching currencies: \(error)")
                return
            }
            
            // Update objects.
            inputCurrencyRecord.setValue(Double(fetchedInputRate), forKey: "rateFromUSD")
            outputCurrencyRecord.setValue(Double(fetchedOutputRate), forKey: "rateFromUSD")
            
            // CoreData save.
            do {
                try managedObjectContext.save()
            } catch {
                print("Error saving currencies: \(error)")
                return
            }

        }) 
        
        task.resume()
        
    }

}

extension Double {
    func split() -> [String] {
        return String(self).characters.split{$0 == "."}.map({
            return String($0)
        })
    }
}
