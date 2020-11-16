//
//  ViewController.swift
//  Example
//
//  Created by Anil Sharma on 3/12/19.
//  Copyright © 2019 Anil Sharma. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, KRCViewControllerDelegate {
    override func viewDidLoad() {
      print("checking in the view")
//        super.viewDidLoad()
//        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
////        let cookieValue = "TGT-1802235-4NmMKoDBlOMeIMQGxKmzXY0LcQvCp4LrjntLiO6s4mVgCTSHiP-cas"
////        let krcViewController = KRCViewController(delegate: self, environment: .production, locale: "en_UK", jurisdiction: "UK", webViewConfiguration: WKWebViewConfiguration())
////        krcViewController.loadViewIfNeeded()
////        krcViewController.login(withHost: "www.unibet.co.uk", cookieValue: cookieValue, locale: "en_UK", jurisdiction: "UK", currency: "GBP", clientId: "String", deviceGroup: "String")
//
        let krcViewController = KRCRNViewController()
        //        krcViewController.myRacingBets()
        self.navigationController?.pushViewController(krcViewController, animated: true)
    }
}

extension ViewController {

    func racingClientDidRequestLogin(_: KRCViewController) {
        NSLog("Racing client requested the host app to display login UI and authenticate customer.")
    }

    func racingClientDidLogout(_: KRCViewController) {
        NSLog("Racing client's customer session expired.")
    }
    
    func racingClientDidRequestNavigationToHome(_: KRCViewController) {
        NSLog("Racing client requested the host app to navigate to the main Sports home page.")
    }

    func racingClient(_: KRCViewController, didRequestNavigationToExternalURL url: URL) {
        NSLog("Racing client requested the host app to navigate to and external URL: \(url.absoluteString)")
    }

    func racingClient(_: KRCViewController, didReceiveUnhandledMessage message: String) {
        NSLog("Racing client received a WebKit message it didn't handle: \(message)")
    }

    func racingClientDidLogin(_: KRCViewController) {
        NSLog("Authenticated racing client successfully")
    }

    func racingClient(_: KRCViewController, didFailLoginWithError error: Error) {
        NSLog("Failed to authenticate racing client: \(error.localizedDescription)")
    }

    func racingClient(_: KRCViewController, didFailLogoutWithError error: Error) {
        NSLog("Failed to log out in racing client: \(error.localizedDescription)")
    }

    func racingClient(_: KRCViewController, didFailNavigationWithError error: Error) {
        NSLog("Failed to navigate racing client: \(error.localizedDescription)")
    }
}
