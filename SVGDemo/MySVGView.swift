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
    
    public var penColor: Fill = Color.white
    
    public init(template: String, frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        if let node = try? SVGParser.parse(path: template) {
            addTap(node: node)
            // add black background
            if let group = node as? Group {
                let rect = Rect.init(x: 1, y: 1, w: 850-2, h: 850-2)
                let backgroundShape = Shape(form: rect, fill: Color.black, tag: ["background"])
                var contents = group.contents
                contents.insert(backgroundShape, at: 0)
                group.contents = contents
                self.node = group
            }else {
                self.node = node
            }
            // layout
            self.contentMode = .scaleAspectFit
        }
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
            shape.fill = MySVGView.randomFill()
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
