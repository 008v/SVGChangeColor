//
//  ViewController.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/4.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import UIKit
import Macaw


class ViewController: UIViewController {
    
    var mySVGView: MySVGView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        
        let svgFrame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width)
        
        mySVGView = MySVGView.init(template: "zen", frame: svgFrame)
        mySVGView.contentMode = .scaleAspectFit

        view.addSubview(mySVGView)
    }
    

}

//extension ViewController: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return mySVGView
//    }
//
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        mySVGView.layoutSubviews()
//        //        if let recognizer = scrollView.pinchGestureRecognizer {
//        //            let location = recognizer.location(in: scrollView)
//        //            let scale = Double(recognizer.scale)
//        //            let anchor = Point(x: Double(location.x), y: Double(location.y))
//        //            mySVGView.node.place = Transform.move(dx: anchor.x * (1.0 - scale), dy: anchor.y * (1.0 - scale)).scale(sx: scale, sy: scale)
//        //        }
//    }
//}

