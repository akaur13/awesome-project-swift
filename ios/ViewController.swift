//
//  ViewController.swift
//  Example
//
//  Created by Anil Sharma on 3/12/19.
//  Copyright © 2019 Anil Sharma. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    override func viewDidLoad() {
      print("Hello world")
        super.viewDidLoad()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
//        let cookieValue = "TGT-1802235-4NmMKoDBlOMeIMQGxKmzXY0LcQvCp4LrjntLiO6s4mVgCTSHiP-cas"
//        let krcViewController = KRCViewController(delegate: self, environment: .production, locale: "en_UK", jurisdiction: "UK", webViewConfiguration: WKWebViewConfiguration())
//        krcViewController.loadViewIfNeeded()
//        krcViewController.login(withHost: "www.unibet.co.uk", cookieValue: cookieValue, locale: "en_UK", jurisdiction: "UK", currency: "GBP", clientId: "String", deviceGroup: "String")
       
        let krcViewController = KRCRNViewController()
        //        krcViewController.myRacingBets()
        self.navigationController?.pushViewController(krcViewController, animated: true)
    }
}
