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
    public var penColor: Fill = Color.white
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
    
    deinit {
        removeObserver(self, forKeyPath: "penMode", context: nil)
    }
    
    public init(template: String, frame: CGRect) {
        super.init(frame: frame)
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
        print("pan")
        if gesture.state == UIGestureRecognizerState.changed {
            if gesture.numberOfTouches == 1 && penMode == 1 {
                let location = gesture.location(in: svgView)
                if let currentNode = svgView.findNodeAt(location: location), currentNode.tag != ["background"] {
                    svgView.replaceColors(node: currentNode)
                }
            }
        }
    }
}
