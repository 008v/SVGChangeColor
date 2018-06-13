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
    var originalTrans: Transform!
    var trans: Transform!
    
    public init(template: String, frame: CGRect) {
        super.init(frame: frame)
        self.template = template
        if let node = try? SVGParser.parse(path: template) {
            pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch(gesture:)))
            panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(gesture:)))
            panGesture.maximumNumberOfTouches = 2
            self.addGestureRecognizer(pinchGesture)
            self.addGestureRecognizer(panGesture)
            addTap(node: node)
            self.node = node
        }
        originalTrans = node.place
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

// MARK: -
extension MySVGView {
    public func addTap(node: Node) {
        if let group = node as? Group {
            for child in group.contents {
                addTap(node: child)
            }
        }else if let shape = node as? Shape {
            shape.onTap { [weak self] (tapEvent) in
                guard let strongSelf = self else { return }
//                strongSelf.replaceColors(node: shape)
                strongSelf.node.place = strongSelf.node.place.move(dx: 100, dy: 0)
                print("tap(node: \(node.tag))")
            }
            shape.onLongTap { [weak self] (longPressEvent) in
                guard let strongSelf = self else { return }
                strongSelf.eyedropper(node: shape)
                print("long press(node: \(node.tag))")
            }
        }
    }
    
    public func replaceColors(node: Node) -> Bool {
//        if let group = node as? Group {
//            for child in group.contents {
//                replaceColors(node: child)
//            }
//            return false
//        }else
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

extension MySVGView {
    @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
//        print("pinch")
        guard gesture.numberOfTouches == 2 else { return }
        if gesture.state == UIGestureRecognizerState.changed {
            let touch0 = gesture.location(ofTouch: 0, in: self)
            let touch1 = gesture.location(ofTouch: 1, in: self)
            let anchor = CGPoint.init(x: (touch0.x + touch1.x) / 2 , y: (touch0.y + touch1.y) / 2)
            // 限制缩放比例: (1.0 ~ 8.0)
            var pinchScale = Double(gesture.scale)
            var scale: Double = 1.0
            if let t = trans, let ot = originalTrans {
                scale = t.m11 / ot.m11
            }
            if pinchScale >= 1.0 {  // 放大
                if scale >= 8.0 {
                    pinchScale = 1.0
                }
            }else {                 // 缩小
                if scale <= 1.0 {
                    node.place = originalTrans
                    trans = originalTrans
                    return
                }
            }
            if let t = trans {
                node.place = t.move(dx: Double(anchor.x) * (1.0 - pinchScale), dy: Double(anchor.y) * (1.0 - pinchScale)).scale(sx: pinchScale, sy: pinchScale)
            }else {
                node.place = Transform.move(dx: Double(anchor.x) * (1.0 - pinchScale), dy: Double(anchor.y) * (1.0 - pinchScale)).scale(sx: pinchScale, sy: pinchScale)
            }
        }else if gesture.state == UIGestureRecognizerState.ended {
            trans = node.place
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
            var scale: Double = 1.0
            if let t = trans, let ot = originalTrans {
                scale = t.m11 / ot.m11
            }
            node.place = node.place.move(dx: Double(translation.x / CGFloat(scale)), dy: Double(translation.y / CGFloat(scale)))
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        }else if gesture.state == UIGestureRecognizerState.ended {
            if gesture.numberOfTouches == 1 && penMode == 1 {
                return
            }
            trans = node.place
        }
    }
}

