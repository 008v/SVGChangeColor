//
//  MySVGView.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/6.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import Foundation
import Macaw

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

open class MySVGView: MacawView {
    
    fileprivate let rootNode = Group()
    fileprivate var svgNode: Node?
    var pinchGesture: UIPinchGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!
    var scale: Double = 1.0
    
//    @IBInspectable open var fileName: String? {
//        didSet {
//            parseSVG()
//            render()
//        }
//    }
    
    public init(f: String?, frame: CGRect) {
        super.init(frame: frame)
        
        if let node = try? SVGParser.parse(path: f ?? "") {
            pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch(gesture:)))
            panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(gesture:)))
            self.addGestureRecognizer(pinchGesture)
            self.addGestureRecognizer(panGesture)
            addTap(node: node)
            svgNode = node
        }
        render()
    }
    
    public init(node: Node = Group(), frame: CGRect) {
        super.init(frame: frame)
        svgNode = node
    }
    
    override public init?(node: Node = Group(), coder aDecoder: NSCoder) {
        super.init(node: Group(), coder: aDecoder)
        svgNode = node
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        self.init(node: Group(), coder: aDecoder)
    }
    
    open override var contentMode: MViewContentMode {
        didSet {
            render()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        render()
    }
    
//    fileprivate func parseSVG() {
//        svgNode = try? SVGParser.parse(path: fileName ?? "")
//    }
    
    fileprivate func render() {
        guard let svgNode = self.svgNode else {
            return
        }
        let viewBounds = self.bounds
        /*
            此处svgNode的bounds写成了固定大小850x850。
            以后如果Node类的bounds()属性如果开放，需要修改回来。
         */
        let nodeBounds = Rect.init(x: 0, y: 0, w: 850, h: 850).cgRect() // svg原始尺寸
//        print(viewBounds,nodeBounds)
//        if let nodeBounds = svgNode.bounds()?.cgRect() {
            let svgWidth = nodeBounds.origin.x + nodeBounds.width
            let svgHeight = nodeBounds.origin.y + nodeBounds.height
            
            let viewAspectRatio = viewBounds.width / viewBounds.height
            let svgAspectRatio = svgWidth / svgHeight
            
            let scaleX = viewBounds.width / svgWidth
            let scaleY = viewBounds.height / svgHeight
            
            switch self.contentMode {
            case .scaleToFill:
                svgNode.place = Transform.scale(
                    sx: Double(scaleX),
                    sy: Double(scaleY)
                )
            case .scaleAspectFill:
                let scaleX, scaleY: CGFloat
                if viewAspectRatio > svgAspectRatio {
                    scaleX = viewBounds.width / svgWidth
                    scaleY = viewBounds.width / (svgWidth / svgAspectRatio)
                } else {
                    scaleX = viewBounds.height / (svgHeight / svgAspectRatio)
                    scaleY = viewBounds.height / svgHeight
                }
                let calculatedWidth = svgWidth * scaleX
                let calculatedHeight = svgHeight * scaleY
                svgNode.place = Transform.move(
                    dx: Double(viewBounds.width / 2 - calculatedWidth / 2),
                    dy: Double(viewBounds.height / 2 - calculatedHeight / 2)
                    ).scale(
                        sx: Double(scaleX),
                        sy: Double(scaleX)
                )
            case .scaleAspectFit:
                let calculatedXWidth = scaleX * svgWidth
                let calculatedXHeight = scaleX * svgHeight
                let calculatedYWidth = scaleY * svgWidth
                let calculatedYHeight = scaleY * svgHeight
                
                if calculatedXWidth <= viewBounds.width && calculatedXHeight <= viewBounds.height {
                    svgNode.place = Transform.move(
                        dx: Double(viewBounds.midX - calculatedXWidth / 2),
                        dy: Double(viewBounds.midY - calculatedXHeight / 2)
                        ).scale(
                            sx: Double(scaleX),
                            sy: Double(scaleX)
                    )
                } else if calculatedYWidth <= viewBounds.width && calculatedYHeight <= viewBounds.height {
                    svgNode.place = Transform.move(
                        dx: Double(viewBounds.midX - calculatedYWidth / 2),
                        dy: Double(viewBounds.midY - calculatedYHeight / 2)
                        ).scale(
                            sx: Double(scaleY),
                            sy: Double(scaleY)
                    )
                }
            case .center:
                svgNode.place = Transform.move(
                    dx: Double(getMidX(viewBounds, nodeBounds)),
                    dy: Double(getMidY(viewBounds, nodeBounds))
                )
            case .top:
                svgNode.place = Transform.move(
                    dx: Double(getMidX(viewBounds, nodeBounds)),
                    dy: 0
                )
            case .bottom:
                svgNode.place = Transform.move(
                    dx: Double(getMidX(viewBounds, nodeBounds)),
                    dy: Double(getBottom(viewBounds, nodeBounds))
                )
            case .left:
                svgNode.place = Transform.move(
                    dx: 0,
                    dy: Double(getMidY(viewBounds, nodeBounds))
                )
            case .right:
                svgNode.place = Transform.move(
                    dx: Double(getRight(viewBounds, nodeBounds)),
                    dy: Double(getMidY(viewBounds, nodeBounds))
                )
            case .topLeft:
                break
            case .topRight:
                svgNode.place = Transform.move(
                    dx: Double(getRight(viewBounds, nodeBounds)),
                    dy: 0
                )
            case .bottomLeft:
                svgNode.place = Transform.move(
                    dx: 0,
                    dy: Double(getBottom(viewBounds, nodeBounds))
                )
            case .bottomRight:
                svgNode.place = Transform.move(
                    dx: Double(getRight(viewBounds, nodeBounds)),
                    dy: Double(getBottom(viewBounds, nodeBounds))
                )
            case .redraw:
                break
            }
//        }
        
        rootNode.contents = [svgNode]
        self.node = rootNode
    }
    
    fileprivate func getMidX(_ viewBounds: CGRect, _ nodeBounds: CGRect) -> CGFloat {
        let viewMidX = viewBounds.midX
        let nodeMidX = nodeBounds.midX + nodeBounds.origin.x
        return viewMidX - nodeMidX
    }
    
    fileprivate func getMidY(_ viewBounds: CGRect, _ nodeBounds: CGRect) -> CGFloat {
        let viewMidY = viewBounds.midY
        let nodeMidY = nodeBounds.midY + nodeBounds.origin.y
        return viewMidY - nodeMidY
    }
    
    fileprivate func getBottom(_ viewBounds: CGRect, _ nodeBounds: CGRect) -> CGFloat {
        return viewBounds.maxY - nodeBounds.maxY + nodeBounds.origin.y
    }
    
    fileprivate func getRight(_ viewBounds: CGRect, _ nodeBounds: CGRect) -> CGFloat {
        return viewBounds.maxX - nodeBounds.maxX + nodeBounds.origin.x
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
            }
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
        scale = Double(gesture.scale)
        let location = gesture.location(in: self)
        let anchor = Point(x: Double(location.x), y: Double(location.y))
        print("pinch(scale = \(scale), anchor = \(location.x, location.y))")
        node.place = Transform.move(dx: anchor.x * (1.0 - scale), dy: anchor.y * (1.0 - scale)).scale(sx: scale, sy: scale)
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        node.place = node.place.move(dx: Double(translation.x / CGFloat(scale)), dy: Double(translation.y / CGFloat(scale)))
        gesture.setTranslation(CGPoint.zero, in: gesture.view)
    }
}

