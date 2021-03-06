/*
 *  DialThumbView.swift
 *  PaymentWheel
 *
 *  Created by Hayder Al-Husseini on 28/06/2020.
 *  Copyright © 2020 kodeba•se ltd.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 */

import UIKit

protocol DialThumbViewDelegate: AnyObject {
    func dialShouldIncrementFundingValue()
    func dialShouldDecrementFundingValue()
}

class DialThumbView: UIView {
    weak var delegate: DialThumbViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let thumbViewFrame = frame
        layer.cornerRadius = thumbViewFrame.size.width * 0.5
        
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0.0, height: 3)
        layer.shadowOpacity = 0.5
        layer.shadowColor = UIColor.black.cgColor
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 5.0
        
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
    }
    
    override func accessibilityIncrement() {
        delegate?.dialShouldIncrementFundingValue()
    }

    override func accessibilityDecrement() {
        delegate?.dialShouldDecrementFundingValue()
    }
}
