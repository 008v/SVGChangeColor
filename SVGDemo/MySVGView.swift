//
//  MySVGView.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/6.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import Foundation
import Macaw

public class MySVGView: MacawView {
    
    public var template: String = ""
    public var penColor: Fill = Color.white
    public var penMode: Int = 0 {                       // 0: tap涂色 1: move涂色
        didSet {
            if penMode == 0 {
                panGesture.minimumNumberOfTouches = 2
            }else if penMode == 1 {
                panGesture.maximumNumberOfTouches = 1
            }
        }
    }
    
    var pinchGesture: UIPinchGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!
    var originalTrans: Transform!           // svg原始大小的transform
    var scaleAspectFitTrans: Transform!     // scaleAspectFit的transform
    var trans: Transform!                   // 当前的transform
    var scaleFit: Double! {
        get {
            return Double(self.bounds.width / 850)
        }
    }
    
    public init(template: String, frame: CGRect) {
        super.init(frame: frame)
        self.template = template
        if let node = try? SVGParser.parse(path: template) {
            // gesture
            pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch(gesture:)))
            panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(gesture:)))
            panGesture.maximumNumberOfTouches = 2
            self.addGestureRecognizer(pinchGesture)
            self.addGestureRecognizer(panGesture)
            addTap(node: node)
            // layout
            self.node = node
            self.contentMode = .scaleAspectFit
        }
        originalTrans = Transform.init(m11: node.place.m11, m12: node.place.m12, m21: node.place.m21, m22: node.place.m22, dx: node.place.dx, dy: node.place.dy)
    }
    
    public init(node: Node = Group(), frame: CGRect) {
        super.init(frame: frame)
        self.node = node
    }
    
    override public init?(node: Node = Group(), coder aDecoder: NSCoder) {
        super.init(node: node, coder: aDecoder)
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        self.init(node: Group(), coder: aDecoder)
    }

}

// MARK: Business
extension MySVGView {
    public func replaceColors(node: Node) -> Bool {
        if let shape = node as? Shape {
            shape.fill = penColor
            return true
        }
        return false
    }
    
    public func eyedropper(node: Node) -> Bool {
        if let shape = node as? Shape, let f = shape.fill {
            penColor = f
            return true
        }
        return false
    }
    
    public func export(size: CGSize = CGSize(width: 850, height: 850)) -> UIImage? {
            UIGraphicsBeginImageContext(size)
            defer {
                UIGraphicsEndImageContext()
            }
            layer.render(in: UIGraphicsGetCurrentContext()!)
            let img =  UIGraphicsGetImageFromCurrentImageContext()
            return img
    }
    
    public func export(size: CGSize = CGSize(width: 850, height: 850)) -> String? {
        UIGraphicsBeginImageContext(size)
        defer {
            UIGraphicsEndImageContext()
        }
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img =  UIGraphicsGetImageFromCurrentImageContext()
        if let i = img {
            if let data = UIImagePNGRepresentation(i) {
                return data.base64EncodedString()
            }
            return nil
        }
        return nil
    }
    
    public func export(size: CGSize = CGSize(width: 850, height: 850), to: String) -> String? {
        UIGraphicsBeginImageContext(size)
        defer {
            UIGraphicsEndImageContext()
        }
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img =  UIGraphicsGetImageFromCurrentImageContext()
        if let i = img {
            if let data = UIImagePNGRepresentation(i) {
                return data.base64EncodedString()
            }
            return nil
        }
        return nil
    }
    
    static func randomFill() -> Fill {
        if arc4random() % 2 == 0 {
            return randomColor()
        }
        return randomLinearGradient()
    }
    
    static func randomColor() -> Color {
        let r = Int(arc4random_uniform(UINT32_MAX) % 255)
        let g = Int(arc4random_uniform(UINT32_MAX) % 255)
        let b = Int(arc4random_uniform(UINT32_MAX) % 255)
        let color = Color.rgba(r: r, g: g, b: b, a: 1.0)
        return color
    }
    
    static func randomLinearGradient() -> LinearGradient {
        var degree: Double = 0
        switch arc4random_uniform(UINT32_MAX) % 4 {
        case 0:
            degree = 0
            break
        case 1:
            degree = 90
            break
        case 2:
            degree = 180
            break
        case 3:
            degree = 270
            break
        default:
            degree = 0
        }
        let linearGradient = LinearGradient.init(degree: degree, from: randomColor(), to: randomColor())
        return linearGradient
    }

}

// MARK: Gesture
extension MySVGView {
    @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
//        print("pinch")
        guard gesture.numberOfTouches == 2 else { return }
        if gesture.state == UIGestureRecognizerState.changed {
            let touch0 = gesture.location(ofTouch: 0, in: self)
            let touch1 = gesture.location(ofTouch: 1, in: self)
            let anchor = CGPoint.init(x: (touch0.x + touch1.x) / 2 , y: (touch0.y + touch1.y) / 2)
            let pinchScale = Double(gesture.scale)
            if let t = trans {
                node.place = t.move(dx: Double(anchor.x) * (1.0 - pinchScale), dy: Double(anchor.y) * (1.0 - pinchScale)).scale(sx: pinchScale, sy: pinchScale)
            }else {
                node.place = Transform.move(dx: Double(anchor.x) * (1.0 - pinchScale), dy: Double(anchor.y) * (1.0 - pinchScale)).scale(sx: pinchScale, sy: pinchScale)
            }
        }else if gesture.state == UIGestureRecognizerState.ended {
            trans = Transform.init(m11: node.place.m11, m12: node.place.m12, m21: node.place.m21, m22: node.place.m22, dx: node.place.dx, dy: node.place.dy)
        }
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
//        print("pan")
        if gesture.state == UIGestureRecognizerState.changed {
            if gesture.numberOfTouches == 1 && penMode == 1 {
                let location = gesture.location(in: self)
                if let currentNode = findNodeAt(location: location) {
                    replaceColors(node: currentNode)
                }
                return
            }
            let translation = gesture.translation(in: gesture.view)
            var scaleToOriginalSVG: Double = Double(bounds.size.width / 850)
            if let t = trans, let ot = originalTrans {
                scaleToOriginalSVG = t.m11 / ot.m11
            }
            print(scaleToOriginalSVG)
            node.place = node.place.move(dx: Double(translation.x / CGFloat(scaleToOriginalSVG) / CGFloat(scaleFit)), dy: Double(translation.y / CGFloat(scaleToOriginalSVG) / CGFloat(scaleFit)))
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
            trans = Transform.init(m11: node.place.m11, m12: node.place.m12, m21: node.place.m21, m22: node.place.m22, dx: node.place.dx, dy: node.place.dy)
        }else if gesture.state == UIGestureRecognizerState.ended {
            if gesture.numberOfTouches == 1 && penMode == 1 {
                return
            }
        }
    }
    
    public func addTap(node: Node) {
        if let group = node as? Group {
            for child in group.contents {
                addTap(node: child)
            }
        }else if let shape = node as? Shape {
            shape.onTap { [weak self] (tapEvent) in
                guard let strongSelf = self else { return }
                strongSelf.replaceColors(node: shape)
                print("tap(node: \(node.tag))")
            }
            shape.onLongTap { [weak self] (longPressEvent) in
                guard let strongSelf = self else { return }
                strongSelf.eyedropper(node: shape)
                print("long press(node: \(node.tag))")
            }
        }
    }
}
