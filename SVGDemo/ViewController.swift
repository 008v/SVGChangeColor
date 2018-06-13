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
