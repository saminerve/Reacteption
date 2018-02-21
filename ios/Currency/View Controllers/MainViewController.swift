//
//  MainViewController.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 11/02/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit

class MainViewController: UIViewController {
    
    var primaryLastLocation:CGPoint = CGPoint(x: 0, y: 0)
    var secondaryLastLocation:CGPoint = CGPoint(x: 0, y: 0)

    var converter: Converter!
    var calculator: Calculator!
    var tapSoundPlayer: AVAudioPlayer!
    var addButtonHighlight: CALayer!
    var minusButtonHighlight: CALayer!
    var fadeInAnimation: CABasicAnimation!
    var fadeOutAnimation: CABasicAnimation!
    var prefs: UserDefaults = UserDefaults.standard
    let notificationCenter = NotificationCenter.default
    
    @IBOutlet weak var outputCurrencyContainer: UIView!
    @IBOutlet weak var inputCurrencyContainer: UIView!
    @IBOutlet weak var inputCurrency: UIButton!
    @IBOutlet weak var outputCurrency: UIButton!
    @IBOutlet weak var inputCurrencyCodeButton: UIButton!
    @IBOutlet weak var outputCurrencyCodeButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var equalsButton: UIButton!
    @IBOutlet weak var inputIndicator: UIView!
    @IBOutlet weak var inputActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var outputActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        converter = Converter()
        calculator = Calculator()
        notificationCenter.addObserver(self,
                                       selector: #selector(MainViewController.didReceiveCoinUpdateNotification),
                                       name:NSNotification.Name(rawValue: "CoinUpdatedNotification"),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(MainViewController.didReceiveUpdateActivityIndicator),
                                       name:NSNotification.Name(rawValue: "UpdateActivityIndicator"),
                                       object: nil)
        
        // Style view.
        inputCurrency.titleLabel?.adjustsFontSizeToFitWidth = true
        outputCurrency.titleLabel?.adjustsFontSizeToFitWidth = true
        inputIndicator.layer.cornerRadius = 2.0
        inputActivityIndicator.isHidden = true
        outputActivityIndicator.isHidden = true
        inputActivityIndicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        outputActivityIndicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        

        // Style highlights for add and minus buttons.
        setupCustomHighlights()

        // If we have the last input currency used saved on the preferences
        // file, let's use it.
        if let currencyCode = prefs.string(forKey: "input") {
            converter.inputCurrency.setTo(currencyCode, update:false, remember: false)
            updateInterface(playSound: false)
        }

        // If we have the last input currency used saved on the preferences
        // file, let's use it.
        if let currencyCode = prefs.string(forKey: "output") {
            converter.outputCurrency.setTo(currencyCode, update:false, remember: false)
            updateInterface(playSound: false)
        }

        // We want to know if the app is opened from the background
        // to restart the input indicator animation.
        notificationCenter.addObserver(self,
                                       selector:#selector(MainViewController.applicationBecameActiveNotification),
                                       name:NSNotification.Name.UIApplicationDidBecomeActive,
                                       object:nil)
        
        // Currency drag to change.
        let inputCurrencyPanRecognizer = UIPanGestureRecognizer(target: self,
                                                                action: #selector(detectPan(recognizer:)))
        let outputCurrencyPanRecognizer = UIPanGestureRecognizer(target: self,
                                                                 action: #selector(detectPan(recognizer:)))
        inputCurrencyContainer.addGestureRecognizer(inputCurrencyPanRecognizer)
        outputCurrencyContainer.addGestureRecognizer(outputCurrencyPanRecognizer)

    }

    override func viewDidAppear(_ animated: Bool) {
        // When we change views the animations stop,
        // so let's restart them when the view appears.
        animateInputIndicator()
        super.viewDidAppear(animated)
    }

    @objc func applicationBecameActiveNotification() {
        // When we put the app on the background the animations stop,
        // so let's restart them when the app is back on the foreground.
        animateInputIndicator()
        // Update currencies.
        converter.updateCurrentCurrencies()
    }

    @IBAction func digitPressed(_ sender: UIButton) {
        guard let digit = sender.titleLabel?.text else {
            print("Error setting digit value.")
            return
        }
        if calculator.settingNewValue {
            converter.clear()
            calculator.settingNewValue = false
        }
        converter.addInput(digit)
        updateInterface()
    }

    @IBAction func clearPressed(_ sender: UIButton) {
        guard !calculator.settingNewValue else {
            calculator.reset()
            updateInterface()
            return
        }
        
        converter.removeLastInput()
        updateInterface()
    }

    @IBAction func switchPressed(_ sender: UIButton) {
        swapInputAndOutputCurrencies()
    }

    @IBAction func addPressed(_ sender: UIButton) {
        calculator.newAddition(converter.parsedInput())
        // Update the input label with the latest calculation,
        // at this point stored as the initial value.
        converter.setInputValue(calculator.initialValue)
        updateInterface()
        // Keep this button highlighted after it's pressed so the user
        // knows a new operation has begun.
        sender.setImage(UIImage(named: "buttonAddIconHighlighted.png"), for: UIControlState())
        addButtonHighlight.add(fadeInAnimation, forKey: "fadeIn")
        addButtonHighlight.opacity = 1
    }

    @IBAction func minusPressed(_ sender: UIButton) {
        calculator.newSubtraction(converter.parsedInput())
        // Update the input label with the latest calculation,
        // at this point stored as the initial value.
        converter.setInputValue(calculator.initialValue)
        updateInterface()
        // Keep this button highlighted after it's pressed so the user
        // knows a new operation has begun.
        sender.setImage(UIImage(named: "buttonSubtractIconHighlighted.png"), for: UIControlState())
        minusButtonHighlight.add(fadeInAnimation, forKey: "fadeIn")
        minusButtonHighlight.opacity = 1
    }

    @IBAction func equalsPressed(_ sender: UIButton) {
        let result = calculator.calculate(Double(converter.parsedInput()))
        converter.setInputValue(result)
        updateInterface()
    }

    @IBAction func dotPressed(_ sender: UIButton) {
        converter.beginDecimalInput()
        updateInterface()
    }

    @IBAction func ouputCurrencyPressed(_ sender: UIButton) {
        swapInputAndOutputCurrencies()
    }

    @IBAction func swipedInput(_ sender: UIGestureRecognizer) {
        // If a user swipes on the input label, remove on digit.
        // The iOS native calculator app also has this hidden feature.
        converter.removeLastInput()
        updateInterface()
    }

    @IBAction func longPressedInput(_ sender: UIGestureRecognizer) {
        // Copy input label text to clipboard after a long press.
        if sender.state == .began {
            UIPasteboard.general.string = inputCurrency.titleLabel!.text
            print("Copied input currency value to clipboard.")
        }
    }

    @IBAction func longPressedOutput(_ sender: UIGestureRecognizer) {
        // Copy input label text to clipboard after a long press.
        if sender.state == .began {
            UIPasteboard.general.string = outputCurrency.titleLabel!.text
            print("Copied output currency value to clipboard.")
        }
    }

    @IBAction func longPressedEquals(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            reset()
        }
    }

    @IBAction func longPressedClear(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            reset()
        }
    }

    func reset() {
        converter.clear()
        calculator.reset()
        updateInterface()
    }
    
    @objc func detectPan(recognizer:UIPanGestureRecognizer) {
        
        let touchedGroup = recognizer.view == outputCurrencyContainer ? outputCurrencyContainer : inputCurrencyContainer
        let siblingGroup = recognizer.view == outputCurrencyContainer ? inputCurrencyContainer : outputCurrencyContainer
        
        if recognizer.state == UIGestureRecognizerState.began {
            primaryLastLocation = touchedGroup!.center
            secondaryLastLocation = siblingGroup!.center
        }
        
        let translation = recognizer.translation(in: touchedGroup?.superview!)
        touchedGroup!.center = CGPoint(x: primaryLastLocation.x, y: primaryLastLocation.y + translation.y)
        siblingGroup!.center = CGPoint(x: secondaryLastLocation.x, y: secondaryLastLocation.y + -translation.y)
        
        if recognizer.state == UIGestureRecognizerState.ended {
            if (recognizer.view == outputCurrencyContainer && translation.y >= 0) || (recognizer.view == inputCurrencyContainer && translation.y <= 0) {
                resetInputAndOutputCurrenciesLocation(panView: recognizer.view!)
            } else {
                let distance = abs(translation.y)
                let velocity = abs(recognizer.velocity(in: touchedGroup?.superview!).y) / 100
                swapInputAndOutputCurrencies(distance: distance, velocity: velocity)
            }
        }
    }
    
    func resetInputAndOutputCurrenciesLocation(panView:UIView) {
        
        // Store all the final positions and colors before animating.
        let inputPosition = panView == inputCurrencyContainer ? primaryLastLocation.y : secondaryLastLocation.y
        let outputPosition = panView == inputCurrencyContainer ? secondaryLastLocation.y : primaryLastLocation.y
        
        // Animate items to their final position.
        UIView.animate(
            withDuration: 0.56,
            delay: 0,
            usingSpringWithDamping: 0.56,
            initialSpringVelocity: 0,
            options: .curveEaseOut,
            animations: {
                self.inputCurrencyContainer.center.y = inputPosition
                self.outputCurrencyContainer.center.y = outputPosition
        },
            completion: nil
        )
    }

    func swapInputAndOutputCurrencies(distance: CGFloat = 0, velocity: CGFloat = 0) {
        // First, hide the spinners.
        hideInputActivityIndicator()
        hideOutputActivityIndicator()
        
        // Store all the final positions and colors before animating.
        let inputPosition = inputCurrencyContainer.center.y
        let inputColor = inputCurrency.titleLabel?.textColor
        let outputPosition = outputCurrencyContainer.center.y
        let outputColor = outputCurrency.titleLabel?.textColor

        // Place items in their initial position before animating.
        inputCurrencyContainer.center.y = outputPosition + distance
        inputCurrency.setTitleColor(outputColor, for: UIControlState())
        outputCurrencyContainer.center.y = inputPosition - distance
        outputCurrency.setTitleColor(inputColor, for: UIControlState())
        
        // Animate items to their final position.
        UIView.animate(
            withDuration: 0.56,
            delay: 0,
            usingSpringWithDamping: 0.56,
            initialSpringVelocity: velocity,
            options: .curveEaseOut,
            animations: {
                self.inputCurrencyContainer.center.y = inputPosition
                self.inputCurrency.setTitleColor(inputColor, for: UIControlState())
                self.outputCurrencyContainer.center.y = outputPosition
                self.outputCurrency.setTitleColor(outputColor, for: UIControlState())
            },
            completion: nil
        )
        
        // After running the animation, update the calculator to use the new currency values.
        calculator.initialValue = converter.convertToOutputCurrency(calculator.initialValue)
        if calculator.operationInProgress && !calculator.settingNewValue {
            converter.swapInputWithOutput(convertInputValue: false)
        } else {
            converter.swapInputWithOutput()
        }
        
        // Update the interface.
        updateInterface(playSound: true, clearOperationButton: false)
        
        // Store new input and output currencies as user preferences.
        prefs.set(converter.inputCurrency.code, forKey: "input")
        prefs.set(converter.outputCurrency.code, forKey: "output")

    }

    func updateInterface(playSound: Bool = true, clearOperationButton: Bool = true) {
        // Update all visible labels and reset buttons to their default styles.
        inputCurrency.setTitle(converter.formattedInput(), for: UIControlState())
        outputCurrency.setTitle(converter.formattedOutput(), for: UIControlState())
        inputCurrencyCodeButton.setTitle(converter.inputCurrency.code, for: UIControlState())
        outputCurrencyCodeButton.setTitle(converter.outputCurrency.code, for: UIControlState())
        if addButtonHighlight.opacity == 1 && clearOperationButton {
            addButtonHighlight.add(fadeOutAnimation, forKey: "fadeOut")
            addButtonHighlight.opacity = 0
            addButton.setImage(UIImage(named: "buttonAddIcon.png"), for: UIControlState())
        }
        if minusButtonHighlight.opacity == 1 && clearOperationButton {
            minusButtonHighlight.add(fadeOutAnimation, forKey: "fadeOut")
            minusButtonHighlight.opacity = 0
            minusButton.setImage(UIImage(named: "buttonSubtractIcon.png"), for: UIControlState())
        }
        if playSound {
            playTapSound()
        }
        inputIndicator.layer.removeAnimation(forKey: "pulse")
        animateInputIndicator()
    }

    func animateInputIndicator() {
        let inputIndicatorAnimation = CAAnimationGroup()
        inputIndicatorAnimation.duration = 1.08
        inputIndicatorAnimation.repeatCount = Float.infinity

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0
        pulse.duration = 0.36
        pulse.beginTime = 0.36
        pulse.autoreverses = true
        pulse.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        inputIndicatorAnimation.animations = [pulse]
        inputIndicator.layer.add(inputIndicatorAnimation, forKey: "pulse")
    }

    func setupCustomHighlights() {
        addButtonHighlight = CALayer()
        addButtonHighlight.backgroundColor = UIColor(red:0.05, green:0.78, blue:0.58, alpha:1.00).cgColor
        addButtonHighlight.frame = CGRect(x: 0, y: 0, width: addButton.frame.size.width * 2, height: addButton.frame.size.height * 2)
        addButtonHighlight.opacity = 0
        addButtonHighlight.masksToBounds = true

        minusButtonHighlight = CALayer()
        minusButtonHighlight.backgroundColor = UIColor(red:0.97, green:0.32, blue:0.32, alpha:1.00).cgColor
        minusButtonHighlight.frame = CGRect(x: 0, y: 0, width: minusButton.frame.size.width * 2, height: minusButton.frame.size.height * 2)
        minusButtonHighlight.opacity = 0
        minusButtonHighlight.masksToBounds = true

        fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0
        fadeInAnimation.toValue = 1
        fadeInAnimation.duration = 0.12
        fadeInAnimation.autoreverses = false
        fadeInAnimation.repeatCount = 1

        fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1
        fadeOutAnimation.toValue = 0
        fadeOutAnimation.duration = 0.12
        fadeOutAnimation.autoreverses = false
        fadeOutAnimation.repeatCount = 1

        addButton.layer.insertSublayer(addButtonHighlight, below: addButton.imageView?.layer)
        minusButton.layer.insertSublayer(minusButtonHighlight, below: minusButton.imageView?.layer)
    }
    
    // MARK: - Sounds
    
    func playTapSound() {
        guard prefs.bool(forKey: "sounds_preference") else {
            return
        }
        
        let path = Bundle.main.path(forResource: "tap", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        
        do {
            try tapSoundPlayer = AVAudioPlayer(contentsOf: url)
            tapSoundPlayer.play()
        } catch {
            print("Could not load audio file.")
        }
    }
    
    // MARK: - Notifications
    
    @objc func didReceiveCoinUpdateNotification(_ notification: Notification) {
        print("Notification received that there's a currency update.")
        let currency: Dictionary<String, String> = notification.userInfo as! Dictionary<String, String>
        let currencyCode: String = currency["currencyCode"]!
        let currencyRate: Double = Double(currency["currencyRate"]!)!
        
        if currencyCode == converter.inputCurrency.code {
            converter.inputCurrency.rate = currencyRate
            print("Updated input currency with data from Notification.")
        }
        if currencyCode == converter.outputCurrency.code {
            converter.outputCurrency.rate = currencyRate
            print("Updated output currency with data from Notification.")
        }
        updateInterface(playSound: false)
    }
    
    @objc func didReceiveUpdateActivityIndicator(_ notification: Notification) {
        guard prefs.bool(forKey: "activity_indicators_preference") else {
            return
        }
        
        print("Notification received to update the activity indicator.")
        let currency: Dictionary<String, String> = notification.userInfo as! Dictionary<String, String>
        let currencyCode: String = currency["currencyCode"]!
        let action: String = currency["action"]!
        
        if currencyCode == converter.inputCurrency.code {
            if action == "show" {
                showInputActivityIndicator()
            }
            if action == "hide" {
                hideInputActivityIndicator()
            }
        }
        if currencyCode == converter.outputCurrency.code {
            if action == "show" {
                showOutputActivityIndicator()
            }
            if action == "hide" {
                hideOutputActivityIndicator()
            }
        }
    }
    
    func showInputActivityIndicator() {
        inputActivityIndicator.isHidden = false
        inputActivityIndicator.startAnimating()
    }
    
    func hideInputActivityIndicator() {
        inputActivityIndicator.isHidden = true
        inputActivityIndicator.stopAnimating()
    }
    
    func showOutputActivityIndicator() {
        outputActivityIndicator.isHidden = false
        outputActivityIndicator.startAnimating()
    }
    
    func hideOutputActivityIndicator() {
        outputActivityIndicator.isHidden = true
        outputActivityIndicator.stopAnimating()
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Pass the currency we are changing (input or output) and
        // the current currency code to the Change Currency View Controller.

        if segue.identifier == "ChangeInputCurrency" {
            let changeCurrencyViewController = (segue.destination as! UINavigationController).topViewController as! ChangeCurrencyViewController
            changeCurrencyViewController.targetCurrency = "input"
            changeCurrencyViewController.selectedCurrency = converter.inputCurrency.code
            changeCurrencyViewController.delegate = self
        }

        if segue.identifier == "ChangeOutputCurrency" {
            let changeCurrencyViewController = (segue.destination as! UINavigationController).topViewController as! ChangeCurrencyViewController
            changeCurrencyViewController.targetCurrency = "output"
            changeCurrencyViewController.selectedCurrency = converter.outputCurrency.code
            changeCurrencyViewController.delegate = self
        }

    }

}

// MARK: - Delegate

extension MainViewController: ChangeCurrencyViewControllerDelegate {

    // After selecting a new currency from the Change Currency View Controller,
    // set it as the new currency and update the interface.
    // At this point, also save it to the user preferences file.
    func didChangeCurrency(_ currencyCode: String, targetCurrency: String) {
        if targetCurrency == "input" {
            // If user changes input currency to be the same as the
            // output currency, swap them.
            if currencyCode == converter.outputCurrency.code {
                converter.swapInputWithOutput()
                converter.outputCurrency.recordAsSelected()
            } else {
                converter.inputCurrency.setTo(currencyCode)
            }
            prefs.set(currencyCode, forKey: "input")
            print("Input currency updated to: \(currencyCode)")
        }
        if targetCurrency == "output" {
            // If user changes output currency to be the same as the
            // input currency, swap them.
            if currencyCode == converter.inputCurrency.code {
                converter.swapInputWithOutput()
                converter.inputCurrency.recordAsSelected()
            } else {
                converter.outputCurrency.setTo(currencyCode)
            }
            prefs.set(currencyCode, forKey: "output")
            print("Output currency updated to: \(currencyCode)")
        }
        updateInterface()
        // Request App Store Review.
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
}
