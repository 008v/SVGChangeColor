//
//  SVGScrollView.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/14.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import UIKit
import Macaw

public class SVGScrollView: UIScrollView {
    public var template: String = ""
    public var penColor: Fill = Color.white {
        didSet {
            svgView.penColor = penColor
        }
    }
    public var penMode: Int = 0 {
        didSet {
            if penMode == 0 {
                panGestureRecognizer.isEnabled = true
                pan.isEnabled = false
            }else if penMode == 1 {
                panGestureRecognizer.isEnabled = false
                pan.isEnabled = true
            }
        }
    }         // 0: tap涂色 1: pan涂色

    var svgView: MySVGView!
    var pan: UIPanGestureRecognizer!
    let maxScale: CGFloat = 40.0        // 最大缩放比
    let minScale: CGFloat = 1.0         // 最小缩放比
    let maxWidth: CGFloat = 3000.0      // 图像渲染的实际最大宽度
    
    public init(template: String, frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        svgView = MySVGView.init(template: template, frame: CGRect.init(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        addSubview(svgView)
        contentSize = svgView.bounds.size
        minimumZoomScale = minScale
        maximumZoomScale = maxScale
        decelerationRate = UIScrollViewDecelerationRateNormal
        delegate = self
        // add pan gesture
        pan = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(gesture:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        addGestureRecognizer(pan)
        panGestureRecognizer.delegate = self
        pinchGestureRecognizer?.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func sendMessage(dic: Dictionary<String, Any>) {
        guard let action = dic["action"] as? Dictionary<String, Any> else {
            return
        }
        if let type = action["type"] as? String, let params = action["params"] as? Dictionary<String, Any> {
            // Set pen color
            if type == "pen_color" {
                let colorType = params["colortype"] as? Int ?? 0
                let colors = params["colors"] as? Array<String> ?? []
                // pure color
                if colorType == 0 {
                    let aColor = Color(val: Int(colors[0], radix: 16)!)
                    penColor = aColor
                // gradient color
                }else {
                    let color0 = Color(val: Int(colors[0], radix: 16)!)
                    let color1 = Color(val: Int(colors[1], radix: 16)!)
                    let grad = params["grad"] as? Dictionary<String, Int> ?? [:]
                    if let x = grad["x"], let y = grad["y"], let z = grad["z"] {
                        if x == 1, y == 0, z == 0 {             // ⇢
                            penColor = LinearGradient(degree: 0, from: color0, to: color1)
                        }else if x == -1, y == 0, z == 0 {      // ⇠
                            penColor = LinearGradient(degree: 180, from: color0, to: color1)
                        }else if x == 0, y == 1, z == 0 {       // ⇡
                            penColor = LinearGradient(degree: 90, from: color0, to: color1)
                        }else if x == 0, y == -1, z == 0 {      // ⇣
                            penColor = LinearGradient(degree: 270, from: color0, to: color1)
                        }else if x == 0, y == 0, z == 1 {       // (⇠⇢)
                            penColor = RadialGradient(r: 1, stops: [Stop(offset: 0, color: color0), Stop(offset: 1, color: color1)])
                        }else if x == 0, y == 0, z == -1 {      // (⇢⇠)
                            penColor = RadialGradient(r: 1, stops: [Stop(offset: 0, color: color1), Stop(offset: 1, color: color0)])
                        }
                    }
                }
            // Set pan mode
            }else if type == "pen_mode" {
                let mode = params["mode"] as? String ?? ""
                // tap to fill
                if mode == "single" {
                    penMode = 0
                // move to fill
                }else {
                    penMode = 1
                }
            }
        }
    }
}

extension SVGScrollView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return svgView
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let zoomWidth = svgView.bounds.size.width * scale
        print(zoomWidth)
        var zoomScale: CGFloat = 1.0
        var transformScale: CGFloat = 1.0
        if zoomWidth <= maxWidth {
            zoomScale = scale
            transformScale = 1.0 // 不缩放
            let trans = svgView.transform
            svgView.transform = CGAffineTransform.init(a: transformScale, b: trans.b, c: trans.c, d: transformScale, tx: trans.tx, ty: trans.ty)
            svgView.frame = CGRect.init(origin: CGPoint.zero, size: CGSize(width: svgView.bounds.size.width * zoomScale, height: svgView.bounds.size.height * zoomScale))
            scrollView.minimumZoomScale = minScale / (svgView.bounds.size.width / bounds.size.width)
            scrollView.maximumZoomScale = maxScale / (svgView.bounds.size.width / bounds.size.width)
        }else {
            return
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
}

extension SVGScrollView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension SVGScrollView {
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.changed {
            if gesture.numberOfTouches == 1 && penMode == 1 {
                let location = gesture.location(in: svgView)
                if let currentNode = svgView.findNodeAt(location: location), currentNode.tag != ["background"] {
                    if let shape = currentNode as? Shape, let shapeFill = shape.fill, shapeFill == penColor {
                        return // 涂过当前画笔颜色的区域不操作
                    }
                    svgView.replaceColors(node: currentNode, color: penColor)
                }
            }
        }
    }
}

extension SVGScrollView {
    func dicToFill(dic: Dictionary<String, Any>) -> Fill {
        
        return Fill()
    }
    
    func fillToDic(fill: Fill) -> Dictionary<String, Any> {
        
        return [:]
    }
}

// MARK:
extension Fill: Equatable {
    public static func == (lhs: Fill, rhs: Fill) -> Bool {
        if let lColor = lhs as? Color, let rColor = rhs as? Color {
            if lColor == rColor {
                return true
            }
        }
        if let lLinearGradient = lhs as? LinearGradient, let rLinearGradient = rhs as? LinearGradient {
            return (lLinearGradient.x1 == rLinearGradient.x1 && lLinearGradient.x2 == rLinearGradient.x2 && lLinearGradient.y1 == rLinearGradient.y1 && lLinearGradient.y2 == rLinearGradient.y2 && lLinearGradient.userSpace == rLinearGradient.userSpace && lLinearGradient.stops.count == rLinearGradient.stops.count)
        }
        if let lRadialGradient = lhs as? RadialGradient, let rRadialGradient = rhs as? RadialGradient {
            return (lRadialGradient.cx == rRadialGradient.cx && lRadialGradient.cy == rRadialGradient.cy && lRadialGradient.fx == rRadialGradient.fx && lRadialGradient.fy == rRadialGradient.fy && lRadialGradient.r == rRadialGradient.r && lRadialGradient.userSpace == rRadialGradient.userSpace && lRadialGradient.stops.count == rRadialGradient.stops.count)
        }
        return false
    }
    
    public static func != (lhs: Fill, rhs: Fill) -> Bool {
        if let lColor = lhs as? Color, let rColor = rhs as? Color {
            if lColor == rColor {
                return false
            }
        }
        if let lLinearGradient = lhs as? LinearGradient, let rLinearGradient = rhs as? LinearGradient {
            return !(lLinearGradient.x1 == rLinearGradient.x1 && lLinearGradient.x2 == rLinearGradient.x2 && lLinearGradient.y1 == rLinearGradient.y1 && lLinearGradient.y2 == rLinearGradient.y2 && lLinearGradient.userSpace == rLinearGradient.userSpace && lLinearGradient.stops.count == rLinearGradient.stops.count)
        }
        if let lRadialGradient = lhs as? RadialGradient, let rRadialGradient = rhs as? RadialGradient {
            return !(lRadialGradient.cx == rRadialGradient.cx && lRadialGradient.cy == rRadialGradient.cy && lRadialGradient.fx == rRadialGradient.fx && lRadialGradient.fy == rRadialGradient.fy && lRadialGradient.r == rRadialGradient.r && lRadialGradient.userSpace == rRadialGradient.userSpace && lRadialGradient.stops.count == rRadialGradient.stops.count)
        }
        return true
    }
}


