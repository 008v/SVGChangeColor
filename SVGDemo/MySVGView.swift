//
//  MySVGView.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/6.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import Foundation
import Macaw

open class MySVGView: MacawView {
    
    var pinchGesture: UIPinchGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!
    var originalTrans: Transform!
    var trans: Transform!
    var isPaint = false {
        didSet {
            if isPaint == true {
                panGesture.minimumNumberOfTouches = 2
            }else {
                panGesture.maximumNumberOfTouches = 1
            }
        }
    }
    
    public init(f: String?, frame: CGRect) {
        super.init(frame: frame)
        if let node = try? SVGParser.parse(path: f ?? "") {
            pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch(gesture:)))
            panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(gesture:)))
            panGesture.maximumNumberOfTouches = 2
            self.addGestureRecognizer(pinchGesture)
            self.addGestureRecognizer(panGesture)
            addTap(node: node)
            self.node = node
        }
        originalTrans = node.place
        isPaint = true
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
                strongSelf.replaceColors(node: shape)
                print("tap")
            }
//            shape.onTouchMoved { (touchEvent) in
//                print("moved")
//            }
//            shape.onTouchPressed { (touchEvent) in
//                print("pressed")
//            }
//            shape.onTouchReleased { (touchEvent) in
//                print("released")
//            }
        }
    }
    
    public func replaceColors(node: Node) {
        if let group = node as? Group {
            for child in group.contents {
                replaceColors(node: child)
            }
        }else if let shape = node as? Shape {
            if let _ = shape.fill as? Color {
                shape.fill = arc4random() % 2 == 0 ? Color.yellow : Color.green
            }
        }
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
            if gesture.numberOfTouches == 1 && isPaint == true {
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
            if gesture.numberOfTouches == 1 && isPaint == true {
                return
            }
            trans = node.place
        }
    }
}

