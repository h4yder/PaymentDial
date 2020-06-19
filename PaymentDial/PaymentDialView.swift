/*
 *  PaymentDialView.swift
 *  PaymentDial
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

@IBDesignable class PaymentDialView: UIView {
    
    @IBOutlet weak private var dialBody: UIView!
    @IBOutlet weak private var textView: UIView!
    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var fundingLabel: UILabel!
    @IBOutlet weak private var bitmapView: UIImageView!
    @IBOutlet weak private var thumbView: UIView!
    @IBOutlet weak private var thumbXConstraint: NSLayoutConstraint!
    @IBOutlet weak private var thumbYConstraint: NSLayoutConstraint!
    @IBOutlet weak private var wedgeView: UIView!
    
    private let salmonColor = UIColor(red: 0.894, green: 0.502, blue: 0.507, alpha: 1.0)
    
    private var distanceFromCenter: CGFloat = 0.0
    private var angle: CGFloat = 0.0
    private var markers: [MarkerView] = []
    private var currentQuadrant: Int = 1
    
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var shouldTriggerImpact = true

    var baseBalance: CGFloat  = 0.0
    var minimumAmount: CGFloat = 5.0
    var maximumFundingAmount: CGFloat = 500.0
    
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    
    private var currentMarker = 0
    
    @IBInspectable var balance: String = "£ 128.00" {
        didSet {
            configureBalance()
        }
    }

    @IBInspectable var funds: String  = "£ 5.00" {
        didSet {
            fundingLabel.text = funds
        }
    }
    
    @IBInspectable var topCurvedText: String = "ACCOUNT BALANCE" {
        didSet {
            updateConstraints()
        }
    }
    
    @IBInspectable var bottomCurvedText: String = "SHOW ME THE MONEY" {
        didSet {
            updateConstraints()
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
        let name = String(describing: PaymentDialView.self)
        let bundle = Bundle(for: PaymentDialView.self)
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
        
        updateRoundedTextView()
        setupThumb()
        setupWedgeView()
        addMarkers()
        configureBalance()
        setupGradient()
    }
    
    override func didMoveToSuperview() {
        guard superview != nil else {
            return
        }
        
        angle = markers[0].angle
        updateThumb()
    }
    
    override func updateConstraints() {
        // Most of the constraints are on the top view
        // Let's make sure it's updated before setting the radius
        dialBody.superview?.layoutIfNeeded()
        [dialBody, textView].forEach {
            let frame = $0?.frame ?? CGRect.zero
            $0?.layer.cornerRadius = frame.size.width * 0.5
        }
        
        distanceFromCenter = (textView.frame.size.width + thumbView.frame.size.width) * 0.5 - thumbView.layer.borderWidth
        
        let layerFrame = dialBody.bounds
        shapeLayer.frame = layerFrame
        gradientLayer.frame = layerFrame
        
        updateRoundedTextView()
        updateThumb()
        updateMarkers()
        super.updateConstraints()
    }
    
    override func prepareForInterfaceBuilder() {
        // Only Interface Builder calls this method
        super.prepareForInterfaceBuilder()

        updateConstraints()
    }
    
    private func configureBalance() {
        balanceLabel.text = balance
        let start = balance.index(balance.startIndex, offsetBy:2)
        let end = balance.endIndex
        baseBalance = CGFloat(Float(balance[start..<end]) ?? 0.0)
    }
    
    private func updateRoundedTextView() {
        let font = UIFont(name: "Avenir-Heavy", size: 45) ?? UIFont.systemFont(ofSize: 15.0)
        let color = UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1.0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attribs: [NSAttributedString.Key: Any] = [.font: font,
                                                      .foregroundColor: color,
                                                      .kern: 1.5,
                                                      .paragraphStyle: paragraphStyle]
        let topLabel = NSAttributedString(string: topCurvedText, attributes: attribs)
        let bottomLabel = NSAttributedString(string: bottomCurvedText, attributes: attribs)
        
        let image = CurvedTextRenderer.renderRoundedText(topLabel: topLabel,
                                                         bottomLabel: bottomLabel,
                                                         frame: bitmapView.frame)
        bitmapView.image = image
    }
    
    private func setupThumb() {
        let thumbViewFrame = thumbView.frame
        thumbView.layer.cornerRadius = thumbViewFrame.size.width * 0.5
        thumbView.backgroundColor = salmonColor
        
        thumbView.layer.shadowRadius = 3
        thumbView.layer.shadowOffset = CGSize(width: 0.0, height: 3)
        thumbView.layer.shadowOpacity = 0.5
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.borderColor = UIColor.white.cgColor
        thumbView.layer.borderWidth = 5.0
    }
    
    private func updateThumb() {
        thumbXConstraint.constant = distanceFromCenter * cos(angle)
        thumbYConstraint.constant = distanceFromCenter * sin(angle)
        
        updateShapeLayerPath()
    }
    
    @IBAction func thumbViewPanned(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator?.prepare()
        case .failed, .cancelled, .ended:
            impactGenerator = nil
            
        default:
            break
        }
        
        let dialFrame = dialBody.frame
        let hitpoint = gesture.location(in: dialBody)
        
        let delta = CGPoint(x: hitpoint.x - (dialFrame.size.width * 0.5),
                            y: hitpoint.y - (dialFrame.size.height * 0.5))
        
        var angle = atan2(delta.y, delta.x)
        
        let cosValue = cos(angle)
        let sinValue = sin(angle)
        
        // Keep track of where we were previously
        let previousQuadrant = currentQuadrant
        /*
                sin-     |      sin-
                cos-  Q3 | Q4   cos+
              ------------------------
                sin+  Q2 | Q1   sin+
                cos-     |      cos+
        */

        // Where are we now?
        if cosValue > 0 {
            currentQuadrant = sinValue > 0 ? 1 : 4
        } else {
            currentQuadrant = sinValue > 0 ? 2 : 3
        }
        
        // Get the last marker's angle so we can stop the thumb from moving past it
        let lastMarkerAngle = markers.last?.angle ?? .pi * -0.5
        var didSnap = false
        // If we're close to a marker snap it to it
        var markerIndex = 0
        for marker in markers {
            if angle > marker.angle - 0.12 && angle < marker.angle + 0.12 {
                
                didSnap = true
                if shouldTriggerImpact {
                    impactGenerator?.impactOccurred()
                    impactGenerator?.prepare()
                    shouldTriggerImpact = false
                }

                angle = marker.angle
                break
            }
            markerIndex += 1
        }
        
        shouldTriggerImpact = !didSnap

        defer {
            updateFigures()
            updateThumb()
            updateDialColorsIfNeeded()
        }

        self.angle = angle
        
        // Stop the thumb from moving past the last marker's position
        if previousQuadrant == 3 && currentQuadrant != 2 && angle > lastMarkerAngle {
            currentQuadrant = previousQuadrant
            self.angle = lastMarkerAngle
            currentMarker = markers.count - 1
            updateDialColors()
            return
        }
        
        // movement is anticlockwise
        // When the thumb's at the first marker, don't let it jump to the last marker if the user keeps panning
        if previousQuadrant == 4 && currentQuadrant == 3 {
            currentQuadrant = previousQuadrant
            self.angle = markers[0].angle
            currentMarker = 0
            updateDialColors()
            return
        }
        
        // Movement is clockwise
        if currentQuadrant == 4 {
            if previousQuadrant == 3 && angle < markers[0].angle {
                // Panning is occuring in the space between the last and first marker
                // Stay on the last marker
                currentQuadrant = previousQuadrant
                self.angle = lastMarkerAngle
            } else {
                // Panning is occuring in the space between the first and the last marker
                // Stay on the first marker
                if angle < markers[0].angle {
                    self.angle = markers[0].angle
                    currentMarker = 0
                    updateDialColors()
                }
            }
            return
        }
    }
    
    private func updateFigures() {
        var value = angle + .pi * 0.5
        if currentQuadrant == 3 {
            value += 2 * .pi
        }
        
        let firstMarker = markers[0].angle + .pi * 0.5
        value -= firstMarker

        value /= (((2 * .pi) - firstMarker)/(maximumFundingAmount))
        fundingLabel.text = String(format: "£ %1.2f", value.isZero ? minimumAmount : value)
        balanceLabel.text = String(format: "£ %1.2f", baseBalance + value)
    }
    
    private func setupWedgeView() {
        wedgeView.layer.borderWidth = 5
        wedgeView.layer.borderColor = UIColor.white.cgColor
        wedgeView.layer.cornerRadius = wedgeView.frame.size.width * 0.5
    }
    
    private func addMarkers() {
        guard markers.isEmpty else {
            return
        }
        
        let angles: [CGFloat] = [-1.0566370614, 0.9625, 2.9817119, .pi * -0.5]
        let superview = thumbView.superview
        
        for angle in angles {
            let marker = MarkerView()
            
            superview?.insertSubview(marker, belowSubview: thumbView)
            
            let centerXConstraint = NSLayoutConstraint(item: marker, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerYConstraint = NSLayoutConstraint(item: marker, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
            
            marker.centerXConstraint = centerXConstraint
            marker.centerYConstraint = centerYConstraint
            marker.angle = angle
            
            addConstraints([centerXConstraint, centerYConstraint])
            
            markers.append(marker)
        }
    }
    
    private func updateMarkers() {
        for marker in markers {
            marker.centerXConstraint.constant = distanceFromCenter * cos(marker.angle)
            marker.centerYConstraint.constant = distanceFromCenter * sin(marker.angle)
        }
    }
    
    func setupGradient() {
        gradientLayer.type = .axial
        
        updateDialColors()
        
        dialBody.layer.masksToBounds = true
        dialBody.layer.insertSublayer(gradientLayer, at: 0)
        

        let frame = dialBody.bounds

        gradientLayer.frame = frame
        gradientLayer.contentsScale = dialBody.contentScaleFactor
        gradientLayer.transform = CATransform3DMakeRotation(.pi, 0, 0, 1)
            
        shapeLayer.frame = frame
        
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.fillColor = dialBody.backgroundColor?.cgColor
        
        dialBody.layer.insertSublayer(shapeLayer, at: 1)
            
        updateShapeLayerPath()
    }
    
    func updateDialColorsIfNeeded() {
        for i in 1..<markers.count {
            let start = markers[i - 1].angle + .pi * 0.5
            var end = markers[i].angle + .pi * 0.5
            
            end = end.isZero ? 2 * .pi : end
            
            var transformedAngle = angle + .pi * 0.5
            if currentQuadrant == 3 {
                transformedAngle += 2 * .pi
            }
            
            let range = start..<end
            if range.contains(transformedAngle) && currentMarker != i - 1 {
                currentMarker = i - 1
                updateDialColors()
                break
            }
        }
    }
    
    func updateDialColors() {
        let start: UIColor
        let end: UIColor
        
        switch currentMarker {
        case 0:
            start = UIColor(red: 228/255, green: 128/255, blue: 114/255, alpha: 1.0)
            end = UIColor(red: 231/255, green: 100/255, blue: 93/255, alpha: 1.0)
            
        case 1:
            start = UIColor(red: 248/255, green: 221/255, blue: 108/255, alpha: 1.0)
            end = UIColor(red: 243/255, green: 178/255, blue: 67/255, alpha: 1.0)
            
        default:
            start = UIColor(red: 191/255, green: 241/255, blue: 124/255, alpha: 1.0)
            end = UIColor(red: 88/255, green: 185/255, blue: 121/255, alpha: 1.0)
            
        }
        
        balanceLabel.textColor = end
        thumbView.backgroundColor = end
        gradientLayer.colors = [start.cgColor, end.cgColor]
    }

    func updateShapeLayerPath() {
        let frame = shapeLayer.frame
        let halfWidth = frame.size.width * 0.5
        let halfHeight = frame.size.height * 0.5
        let path = CGMutablePath()
            
        path.move(to: CGPoint(x: halfWidth, y: 0.0))
        path.addLine(to: CGPoint(x: halfWidth, y: halfHeight))

        let dialX = halfWidth + frame.size.width * cos(angle)
        let dialY = halfHeight + frame.size.height * sin(angle)

        path.addLine(to: CGPoint(x: dialX, y: dialY))
                        
        if currentQuadrant == 2 {
            path.addLine(to: CGPoint(x:dialX, y: frame.size.height))
            path.addLine(to: CGPoint(x:0.0, y: frame.size.height))
        } else if currentQuadrant == 3 {
            path.addLine(to: CGPoint(x:dialX, y: frame.size.height))
            path.addLine(to: CGPoint(x:dialX, y: 0.0))
        } else {
            path.addLine(to: CGPoint(x:frame.size.width, y: dialY))
            path.addLine(to: CGPoint(x:frame.size.width, y: frame.size.height))
            path.addLine(to: CGPoint(x:0.0, y: frame.size.height))
        }
        
        path.addLine(to: CGPoint(x:0.0, y: 0.0))
        path.addLine(to: CGPoint(x: halfWidth + 5, y: 0.0))
        path.closeSubpath()
        
        shapeLayer.path = path
    }
}
