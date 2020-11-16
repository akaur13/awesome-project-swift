//
//  KRCRNViewController.swift
//  
//
//  Created by Anil Sharma on 11/9/20.
//

import UIKit
import React

public class KRCRNViewController: UIViewController {

    override public func viewDidLoad() {
      print("check the view")
        super.viewDidLoad()
        // Do any additional setup after loading the view.

            let jsCodeLocation = URL(string: "http://localhost:8081/index.bundle?platform=ios")!
//        guard let jsCodeLocation = Bundle(for: KRCRNViewController.self).url(forResource: "KindredRacing.bundle", withExtension: "js") else {
//            preconditionFailure()
//        }
        print(jsCodeLocation)
        let mockData:NSDictionary = ["scores":
            [
                ["name":"Golu", "value":"42"],
                ["name":"Molu", "value":"10"],
                ["name":"Dolu", "value":"15"]
            ]
        ]


        let rootView = RCTRootView(
            bundleURL: jsCodeLocation,
            moduleName: "main",
            initialProperties: mockData as [NSObject : AnyObject],
            launchOptions: nil
        )
        self.view = rootView
    }
}


