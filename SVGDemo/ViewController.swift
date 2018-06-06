//
//  ViewController.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/4.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import UIKit
import Macaw


class ViewController: UIViewController, UIScrollViewDelegate {
    
    var scrollView: UIScrollView!
    var mySVGView: MySVGView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView.init(frame: view.bounds)
        mySVGView = MySVGView.init(f: "zen", frame: scrollView.bounds)
        mySVGView.contentMode = .scaleAspectFit
        scrollView.addSubview(mySVGView)
        scrollView.contentSize = mySVGView.bounds.size
        scrollView.maximumZoomScale = 8.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        

    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mySVGView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        mySVGView.layoutSubviews()
//        if let recognizer = scrollView.pinchGestureRecognizer {
//            let location = recognizer.location(in: scrollView)
//            let scale = Double(recognizer.scale)
//            let anchor = Point(x: Double(location.x), y: Double(location.y))
//            mySVGView.node.place = Transform.move(dx: anchor.x * (1.0 - scale), dy: anchor.y * (1.0 - scale)).scale(sx: scale, sy: scale)
//        }
    }
}

