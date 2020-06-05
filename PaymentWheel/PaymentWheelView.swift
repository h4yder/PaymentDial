/*
 *  PaymentWheelView.swift
 *  PaymentWheel
 *
 *  Created by Hayder Al-Husseini on 05/06/2020.
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

@IBDesignable class PaymentWheelView: UIView {
    
    @IBOutlet weak private var wheelBody: UIView!
    @IBOutlet weak private var textView: UIView!
    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var fundingLabel: UILabel!
    
    @IBInspectable var balance: String = "£ 128.00" {
        didSet {
            balanceLabel.text = balance
        }
    }

    @IBInspectable var funds: String  = "£ 5.00" {
        didSet {
            fundingLabel.text = funds
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        // Load the nib
        let name = String(describing: PaymentWheelView.self)
        let bundle = Bundle(for: PaymentWheelView.self)
        guard let objects = bundle.loadNibNamed(name, owner: self, options: .none),
            let topView = objects.first as? UIView else {
            return
        }
        
        // Add the top view from the nib to our view's hierarchy
        addSubview(topView)
        
        // Set up the constraints by pinning the top view to it's superview
        topView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([topView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     topView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     topView.topAnchor.constraint(equalTo: topAnchor),
                                     topView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    override func updateConstraints() {
        // Most of the constraints are on the top view
        // Let's make sure it's updated before setting the radius
        wheelBody.superview?.layoutIfNeeded()
        [wheelBody, textView].forEach {
            let frame = $0?.frame ?? CGRect.zero
            $0?.layer.cornerRadius = frame.size.width * 0.5
        }
        
        super.updateConstraints()
    }
    
    override func prepareForInterfaceBuilder() {
        // Only Interface Builder calls this method
        super.prepareForInterfaceBuilder()

        updateConstraints()
    }
}
