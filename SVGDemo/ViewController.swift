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
    
    var svgScrollView: SVGScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        
        let svgFrame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        svgScrollView = SVGScrollView.init(template: "classical_1-0-3", frame: svgFrame)
        svgScrollView.penMode = 1
        let dicSetPenColor = ["action":
                            ["type": "pen_color",
                             "params": ["colortype": 1,
                                        "colors": ["f0db09", "f66a69"],
                                        "grad": ["x": 0, "y": 0, "z": -1]]
                            ]
                  ]
        let dicSetPenMode = ["action":
                                ["type": "pen_mode",
                                 "params": ["mode": "single"]
                                ]
                            ]
        svgScrollView.sendMessage(dic: dicSetPenColor)
        svgScrollView.sendMessage(dic: dicSetPenMode)
        view.addSubview(svgScrollView)
    }
    

}
