//
//  ViewController.swift
//  SVGDemo
//
//  Created by WEI QIN on 2018/6/4.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var svgScrollView: SVGScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        
        let svgFrame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        svgScrollView = SVGScrollView.init(template: "zen", frame: svgFrame)
        svgScrollView.penMode = 1
        view.addSubview(svgScrollView)
    }
    

}
