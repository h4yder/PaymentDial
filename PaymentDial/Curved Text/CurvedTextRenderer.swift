/*
 *  CurvedTextRenderer.swift
 *  PaymentWheel
 *
 *  Created by Hayder Al-Husseini on 11/06/2020.
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

final class CurvedTextRenderer {
    private struct Curve {
        let points: [CGPoint]
        let tangents: [CGPoint]
    }
    
    private struct Constants {
        static let maximumFontSizeDelta: CGFloat = 35.0
    }
    
    private var bitmap: Bitmap!
    
    private static func accessibilityFontSizeDelta() -> CGFloat {
        let contentSizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        // Based on Title 3 Row in the table at
        // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
        switch contentSizeCategory {
        case .extraSmall:
            return -3.0
            
        case .small:
            return -2.0
            
        case .medium:
            return -1.0
            
        case .large:
            return 0.0
            
        case .extraLarge:
            return 2.0
            
        case .extraExtraLarge:
            return 4.0
            
        case .extraExtraExtraLarge:
            return 6.0
            
        // Accessibility sizes
        case .accessibilityMedium:
            return 11.0
            
        case .accessibilityLarge:
            return 17.0
            
        case .accessibilityExtraLarge:
            return 23.0
            
        case .accessibilityExtraExtraLarge:
            return 29.0
            
        case .accessibilityExtraExtraExtraLarge:
            return Constants.maximumFontSizeDelta
            
        default:
            return 0
        }
    }
    
    private static func accessibleAttributedString(for source: NSAttributedString) -> NSAttributedString {
        var sourceFont: UIFont
        
        // Get the attributed string's font
        if let attributedStringFont = source.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
            sourceFont = attributedStringFont
        } else {
            sourceFont = UIFont.systemFont(ofSize: 12)
        }
        
        // Get the amount we need to change our font sizw by
        let delta = accessibilityFontSizeDelta()

        guard let accessibleFont = UIFont(name: sourceFont.fontName,
                                          size: sourceFont.pointSize + delta) else {
                                            return source
        }
        
        // Return a new string with our new font
        let range = NSRange(location: 0, length: source.length)
        let accessibleAttributedString = NSMutableAttributedString(attributedString: source)
        accessibleAttributedString.addAttribute(.font, value: accessibleFont, range: range)
        
        return accessibleAttributedString
    }
    
    static func renderRoundedText(topLabel: NSAttributedString, bottomLabel: NSAttributedString, frame: CGRect) -> UIImage? {
        
        let accessibleTopLabel = accessibleAttributedString(for: topLabel)
        let accessibleBottomLabel = accessibleAttributedString(for: bottomLabel)
        
        let renderer = CurvedTextRenderer()
        renderer.bitmap = Bitmap(width: frame.size.width, height: frame.size.height)
        
        let scale = UIScreen.main.scale
        let scaledFrame = CGRect(x: frame.origin.x * scale,
                                 y: frame.origin.y * scale,
                                 width: frame.size.width * scale,
                                 height: frame.size.height * scale)
        let fontSizeFor: (NSAttributedString)->CGFloat = { string in
            guard let font = string.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
                return 12
            }
            
            return font.pointSize
        }
        
        let delta = accessibilityFontSizeDelta()
        let factor: CGFloat = 0.7
        let lineHeightFactor = delta >= 0 ? factor * (1 - delta/Constants.maximumFontSizeDelta) : factor
        let lineHeight: CGFloat = fontSizeFor(accessibleTopLabel) * (1 + lineHeightFactor)
        
        let textFrame = CGRect(x: scaledFrame.origin.x + lineHeight,
                               y: scaledFrame.origin.y + lineHeight,
                               width: scaledFrame.size.width - lineHeight * 2,
                               height: scaledFrame.size.height - lineHeight * 2)
        
        
        let start = CGPoint(x: textFrame.origin.x,
                            y: textFrame.origin.y + textFrame.size.height * 0.5)
        let controlPoint1 = CGPoint(x: textFrame.origin.x + textFrame.size.width * 0.05,
                                    y: textFrame.origin.y + textFrame.size.height * 0.5 + textFrame.size.height * (1.0/1.5))
        let controlPoint2 = CGPoint(x: textFrame.origin.x + textFrame.size.width * 0.95,
                                    y: textFrame.origin.y + textFrame.size.height * 0.5 + textFrame.size.height * (1.0/1.5))
        let end = CGPoint(x: textFrame.origin.x + textFrame.size.width,
                          y: textFrame.origin.y + textFrame.size.height * 0.5)
        
        let topCurve = renderer.computeBezierCurve(start: start,
                                                   controlPoint1: controlPoint1,
                                                   controlPoint2: controlPoint2,
                                                   end: end)
        
        renderer.render(attributedString: accessibleTopLabel, curve: topCurve, bitmap: renderer.bitmap)
        
        let bottomFactor: CGFloat = 0.3
        let bottomLineHeightFactor = delta >= 0 ? (1 - bottomFactor) * (delta/Constants.maximumFontSizeDelta) : 0.0
        let fontSize = fontSizeFor(accessibleBottomLabel)
        let bottomLineHeight = fontSize * (1 - bottomLineHeightFactor)
        
        let bottomTextFrame = CGRect(x: scaledFrame.origin.x + bottomLineHeight,
                                     y: scaledFrame.origin.y + bottomLineHeight,
                                     width: scaledFrame.size.width - bottomLineHeight * 2,
                                     height: scaledFrame.size.height - bottomLineHeight * 2)
        
        let bottomStart = CGPoint(x: bottomTextFrame.origin.x,
                                  y: bottomTextFrame.origin.y + bottomTextFrame.size.height * 0.5)
        let bottomCP1 = CGPoint(x: bottomTextFrame.origin.x + bottomTextFrame.size.width * 0.05,
                                y: bottomTextFrame.origin.y + bottomTextFrame.size.height * 0.5 - bottomTextFrame.size.height * (1.0/1.5))
        let bottomCP2 = CGPoint(x: bottomTextFrame.origin.x + bottomTextFrame.size.width * 0.95,
                                y: bottomTextFrame.origin.y + bottomTextFrame.size.height * 0.5 - bottomTextFrame.size.height * (1.0/1.5))
        let bottomEnd = CGPoint(x: bottomTextFrame.origin.x + bottomTextFrame.size.width,
                                y: bottomTextFrame.origin.y + bottomTextFrame.size.height * 0.5)
        
        let bottomCurve = renderer.computeBezierCurve(start: bottomStart,
                                                      controlPoint1: bottomCP1,
                                                      controlPoint2: bottomCP2,
                                                      end: bottomEnd)
        
        renderer.render(attributedString: accessibleBottomLabel, curve: bottomCurve, bitmap: renderer.bitmap)
        
        guard let cgImage = renderer.bitmap.cgImage else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
//    private func computeBezierCurve(start cp0: CGPoint, controlPoint1 cp1: CGPoint, controlPoint2 cp2: CGPoint, end cp3: CGPoint) -> Curve {
//        var points = [CGPoint]()
//        var tangents = [CGPoint]()
//        // p(t) = (1 - t)^3cp0 + 3t(1- t)^2cp1 + 3(1 - t)t^2*cp2 + t3 * cp3
//
//        for t: CGFloat in stride(from: 0.0, through: 1.0, by: 0.001) {
//            let tt = t * t
//            let ttt = tt * t
//            let oneMinusT = 1 - t
//            let oneMinusTSquared = oneMinusT * oneMinusT
//            let oneMinusTCubed = oneMinusTSquared * oneMinusT
//
//            let a: CGPoint = oneMinusTCubed * cp0
//            let b: CGPoint = 3 * t * oneMinusTSquared * cp1
//            let c: CGPoint = 3 * oneMinusT * tt * cp2
//            let d: CGPoint = ttt * cp3
//
//            let q: CGPoint = a + b + c + d
//            points.append(q)
//
//            //(3*(1-t)*(1-t) * (control1X - startX)) + ((6 * (1-t) * t) * (control2X - control1X)) + (3 * t * t * (endX - control2X));
//
//            let t: CGPoint  = (3 * oneMinusTSquared * (cp1 - cp0)) + (6 * oneMinusT * t * (cp2 - cp1)) + (3 * tt * (cp3-cp2))
//            tangents.append(t)
//        }
//
//        return Curve(points: points, tangents: tangents)
//    }
    
    private func computeBezierCurve(start cp0: CGPoint, controlPoint1 cp1: CGPoint, controlPoint2 cp2: CGPoint, end cp3: CGPoint) -> Curve {
        var points = [CGPoint]()
        var tangents = [CGPoint]()
        let path = CGMutablePath()
        path.move(to: cp0)
        // p(t) = (1 - t)^3cp0 + 3t(1- t)^2cp1 + 3(1 - t)t^2*cp2 + t3 * cp3
        
        for t: CGFloat in stride(from: 0.0, through: 1.0, by: 0.001) {
            let tt = t * t
            let ttt = tt * t
            let oneMinusT = 1 - t
            let oneMinusTSquared = oneMinusT * oneMinusT
            let oneMinusTCubed = oneMinusTSquared * oneMinusT
            
            let a: CGPoint = oneMinusTCubed * cp0
            let b: CGPoint = 3 * t * oneMinusTSquared * cp1
            let c: CGPoint = 3 * oneMinusT * tt * cp2
            let d: CGPoint = ttt * cp3
            
            let q: CGPoint = a + b + c + d
            points.append(q)
            
            path.addLine(to: q)
                
            // Source wikipedia
            //(3*(1-t)*(1-t) * (control1X - startX)) + ((6 * (1-t) * t) * (control2X - control1X)) + (3 * t * t * (endX - control2X));

            let t: CGPoint  = (3 * oneMinusTSquared * (cp1 - cp0)) + (6 * oneMinusT * t * (cp2 - cp1)) + (3 * tt * (cp3-cp2))
            tangents.append(t)
            
        }
        
        bitmap.context.saveGState()
        bitmap.context.addPath(path)
        bitmap.context.setStrokeColor(UIColor.red.cgColor)
        //bitmap.context.strokePath()
        bitmap.context.restoreGState()
        
        return Curve(points: points, tangents: tangents)
    }

    
    private func indexOfStartPoint(with glyphRun: CTRun, attributedString: NSAttributedString, curve: Curve) -> Int {
        guard let paragraphStyle = attributedString.attribute(.paragraphStyle,
                                                              at: 0,
                                                              effectiveRange: nil) as? NSParagraphStyle, paragraphStyle.alignment != .left else {
            return 1
        }
        
        var kern = CGFloat.zero
        if let kernAttrib = attributedString.attribute(.kern,
                                                       at: 0,
                                                       effectiveRange: nil) as? CGFloat {
            kern = kernAttrib
        }
        
        var width = CGFloat.zero
        for i in 0..<Int(CTRunGetGlyphCount(glyphRun)) {
            let range = CFRangeMake(i, 1)
            width += CGFloat(CTRunGetTypographicBounds(glyphRun, range, nil, nil, nil)) + kern
        }

        var curveDistance = CGFloat.zero
        for i in 1..<curve.points.count {
            let point = curve.points[i] - curve.points[0]
            curveDistance += point.distance(from: curve.points[i - 1] - curve.points[0])
        }
        
        var startPoint = CGFloat.zero

        if paragraphStyle.alignment == .right {
            startPoint = curveDistance - width
        } else if paragraphStyle.alignment == .center {
            startPoint = (curveDistance - width) * 0.5
        }

        var distance = CGFloat.zero
        for i in 1..<curve.points.count {
            let point = curve.points[i] - curve.points[0]
            distance += point.distance(from: curve.points[i - 1] - curve.points[0])
            if distance >= startPoint {
                return i
            }
        }
        
        return 1
    }
        
    private func render(attributedString: NSAttributedString, curve: Curve, bitmap: Bitmap) {
        let line = CTLineCreateWithAttributedString(attributedString)
        
        guard let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
            let glyphRun = glyphRuns.first else {
            fatalError()
        }
    
        var kern = CGFloat.zero
        if let kernAttrib = attributedString.attribute(.kern,
                                                       at: 0,
                                                       effectiveRange: nil) as? CGFloat {
            kern = kernAttrib
        }
        
        let indexOfStartPoint = self.indexOfStartPoint(with: glyphRun,
                                                       attributedString: attributedString,
                                                       curve: curve)
        
        let glyphCount = Int(CTRunGetGlyphCount(glyphRun))
        var j = indexOfStartPoint
        for i in 0..<glyphCount {
                let range = CFRangeMake(i, 1)
                
            let width = CGFloat(CTRunGetTypographicBounds(glyphRun, range, nil, nil, nil)) + kern
            
            var distance = CGFloat.zero
            
            for k in j..<curve.points.count {
                let point = curve.points[k] - curve.points[0]
                distance += point.distance(from: curve.points[k - 1] - curve.points[0])
                
                guard width < distance else {
                    continue
                }
                
                let tangentIndex = Int(Double(k - j) * 0.5) + j - 1
                let p0 = curve.points[j - 1]
                let slope = curve.tangents[tangentIndex]
                let angle = atan2(slope.y, slope.x)
                
                bitmap.context.saveGState()

                bitmap.context.translateBy(x: p0.x, y:p0.y)
                bitmap.context.rotate(by: angle)

                let font: UIFont
                if let uifont = attributedString.attribute(.font, at: i, effectiveRange: nil) as? UIFont {
                    font = uifont
                } else {
                    font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
                }
                
                let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
                let cgFont = CTFontCopyGraphicsFont(ctFont, nil)
                
                let textColor: CGColor
                if let color = attributedString.attribute(.foregroundColor, at: i, effectiveRange: nil) as? UIColor {
                    textColor = color.cgColor
                } else {
                    textColor = UIColor.black.cgColor
                }

                bitmap.context.setFont(cgFont)
                bitmap.context.setFontSize(font.pointSize)
                bitmap.context.setFillColor(textColor)
                
                var glyph =  CGGlyph()
                CTRunGetGlyphs(glyphRun, range, &glyph)
                bitmap.context.showGlyphs([glyph], at: [.zero])
                bitmap.context.restoreGState()
                j = k
                break
            }
        }
    }
}

