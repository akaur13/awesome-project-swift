//
//  KRCViewController.swift
//  KRCFramework
//
//  Created by Anil Sharma on 3/12/19.
//  Copyright © 2019 Anil Sharma. All rights reserved.
//

import UIKit
import WebKit

public enum KRCError: Error {
    case invalidAuthenticationCookie
    case invalidURLFormat
    case webViewNotReady
    case invalidGameLauncherResponse(Data?)

    public var localizedDescription: String {
        switch self {
        case .invalidAuthenticationCookie:
            return "Invalid authentication cookie"
        case .invalidURLFormat:
            return "Invalid racing URL format: racing URLs must contain a fragment link"
        case .webViewNotReady:
            return "Web view is not ready for navigation"
        case .invalidGameLauncherResponse(let response):
            var errorDescription = "Failed to parse game launcher response"
            if let response = response, let responseString = String(data: response, encoding: .utf8) {
                errorDescription += ": \(responseString)"
            }
            return errorDescription
        }
    }
}

/// Kindred development environment.
public enum KRCEnvironment {
    case integration, qa, production

    fileprivate var domainComponent: String {
        switch self {
        case .qa:
            return "-qa"
        case .integration:
            return "-integration"
        case .production:
            return ""
        }
    }
}

// Message handlers for communicating javascript to native
private enum KRCMessageHandler: String {
    case login = "loginHandler"
    case logout = "logoutHandler"
    case timeout = "timeoutHandler"
    case sports = "opensportsHandler"
    case externalURL = "openExternalURLHandler"
}

/// Protocol for KRC (Kindred Racing Client) view controller's delegate.
public protocol KRCViewControllerDelegate: AnyObject {
    /// Racing client requested the host app to display login UI and authenticate customer.
    func racingClientDidRequestLogin(_: KRCViewController)
    /// Racing client successfully completed session takeover, and managed to log in.
    func racingClientDidLogin(_: KRCViewController)
    /// Racing client failed log in, most likely failing to take over the session.
    func racingClient(_: KRCViewController, didFailLoginWithError error: Error)
    /// Racing client's customer session expired.
    ///  - Note:
    ///  Typically, host app needs to either extend the session and handover new session token to the racing client, or log out the user.
    func racingClientDidLogout(_: KRCViewController)
    /// Racing client attempted to logout, but failed with an error.
    func racingClient(_: KRCViewController, didFailLogoutWithError error: Error)
    /// Racing client requested the host app to navigate to the main Sports home page.
    func racingClientDidRequestNavigationToHome(_: KRCViewController)
    /// Racing client requested the host app to navigate to and external URL.
    func racingClient(_: KRCViewController, didRequestNavigationToExternalURL url: URL)
    /// Racing client failed an attempted navigation.
    func racingClient(_: KRCViewController, didFailNavigationWithError error: Error)
    /// Racing client received a WebKit message it didn't handle.
    func racingClient(_: KRCViewController, didReceiveUnhandledMessage message: String)
}

/// Main KRC (Kindred Racing Client) view controller, providing primary entry point for KRC UI and API.
public class KRCViewController: UIViewController {
    
    /// KRC delegate
    public weak var delegate: KRCViewControllerDelegate?
    private let environment: KRCEnvironment
    private var locale: String
    private var jurisdiction: String
    private var webView: WKWebView
    
    /// Initialises an instance of `KRCViewController`.
    /// - Parameters:
    ///   - delegate: Delegate
    ///   - environment: Kindred environment
    ///   - locale: Current market's locale identifier
    ///   - jurisdiction: Current market's jurisdiction
    public init(delegate: KRCViewControllerDelegate, environment: KRCEnvironment, locale: String, jurisdiction: String, webViewConfiguration configuration: WKWebViewConfiguration) {
        self.delegate = delegate
        self.environment = environment
        self.locale = locale
        self.jurisdiction = jurisdiction
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: Bundle(for: KRCViewController.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Allows the host app to handover customer session to KRC.
    /// - Parameters:
    ///   - host: API endpoint host, which will be specific to market and environment
    ///   - cookieValue: Kindred's TGT cookie value
    ///   - locale: Current market's locale identifier
    ///   - jurisdiction: Current market's jurisdiction
    ///   - currency: Customer currency code
    ///   - clientId: Customer client identifier
    ///   - deviceGroup: Device type identifier
    public func login(withHost host: String, cookieValue: String, locale: String, jurisdiction: String, currency: String, clientId: String, deviceGroup: String) {

        guard !cookieValue.isEmpty else {
            delegate?.racingClient(self, didFailLoginWithError: KRCError.invalidAuthenticationCookie)
            return
        }
        guard isViewLoaded else {
            delegate?.racingClient(self, didFailLoginWithError: KRCError.webViewNotReady)
            return
        }
        guard let gameLauncherURL = URL(string: makeGameLauncherURL(host, jurisdiction, locale, currency))  else {
            delegate?.racingClient(self, didFailLoginWithError: KRCError.invalidURLFormat)
            return
        }
        // TODO: Authenticate using provided values (and instance properties `locale` and  `jurisdiction`)
        var gameLauncherRequest = URLRequest(url: gameLauncherURL)
        gameLauncherRequest.setValue("CASTGC_LOGOUT=\(cookieValue);", forHTTPHeaderField: "Cookie")
        let task = self.makeLoginDataTask(gameLauncherRequest, jurisdiction: jurisdiction) { result in
            switch result {
            case .success:
                self.delegate?.racingClientDidLogin(self)
            case .failure(let error):
                self.delegate?.racingClient(self, didFailLoginWithError: error)
            }
        }
        task.resume()
    }

    /// Navigates to customer's bet history. Customer needs to be logged in first.
    ///
    /// - Note:
    /// This can be used for deeplinking for url as well. We need url that is getting passed and we can load the page using this method.
    public func navigateToBetHistory() {
        navigateToURL(hashString: "bethistory") { result in
            if case .failure(let error) = result {
                self.delegate?.racingClient(self, didFailNavigationWithError: error)
            }
        }
    }

    /// Navigates to a racing URL.
    ///
    /// - Note:
    ///   Responds to URLs of format: `https://www.unibet.com/betting/racing?clientId=unibetpro_mobilephone-ios_5.17.0#/lobby/greyhounds`
    public func navigateToRacingURL(_ racingURL: URL) {
        // Check that URL has a fragment part.
        guard let fragment = racingURL.fragment else {
            self.delegate?.racingClient(self, didFailNavigationWithError: KRCError.invalidURLFormat)
            return
        }

        // TODO: Basic url map can be kept to see url belongs to our expected urls
        // or get response from js function call and logic stays there. In this way no need to maintain list here
        navigateToURL(hashString: fragment) { result in
            if case .failure(let error) = result {
                self.delegate?.racingClient(self, didFailNavigationWithError: error)
            }
        }
    }
    
    /// Logs the customer out.
    public func logout() {
        guard isViewLoaded else {
            return
        }

        // setup initial variables
        injectEnvironmentVariables { result in
            if case .failure(let error) = result {
                self.delegate?.racingClient(self, didFailLogoutWithError: error)
                return
            }
            let logoutJS = """
            window.__KRC_REDUX_STORE__.dispatch({type: "Auth.LoggedOut"});
            """
            // We do not care when logout fails
            self.insertJS(js: logoutJS) { result in
                if case .failure(let error) = result {
                    self.delegate?.racingClient(self, didFailLogoutWithError: error)
                    return
                }
            }
        }
    }
    
    override public func loadView() {
        addMessageHandlers(to: webView)
        view = webView
    }

    private func addMessageHandlers(to webView: WKWebView) {
        webView.configuration.userContentController.add(self, name: KRCMessageHandler.login.rawValue)
        webView.configuration.userContentController.add(self, name: KRCMessageHandler.logout.rawValue)
        webView.configuration.userContentController.add(self, name: KRCMessageHandler.timeout.rawValue)
        webView.configuration.userContentController.add(self, name: KRCMessageHandler.sports.rawValue)
        webView.configuration.userContentController.add(self, name: KRCMessageHandler.externalURL.rawValue)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        injectEnvironmentVariables { result in
            guard case .success = result else {
                return
            }

            self.loadStaticPage()
        }
    }
}

private extension KRCViewController {
    func makeGameLauncherURL(_ host: String, _ jurisdiction: String, _ locale: String, _ currency: String) -> String {
         return "https://\(host)/ugracing-rest-api/gameLauncher.json?gameId=FrankelLobby&uniqueGameId=FrankelLobby%40ugracing&locale=\(locale)&brand=unibet&currency=\(currency)&clientId=polopoly_mobilephone-ios&deviceGroup=mobilephone&deviceOs=ios&jurisdiction=\(jurisdiction)&useRealMoney=true&marketLocale=\(locale)&_=1579754851607"
    }

    func makeLoginDataTask(_ gameLauncherRequest: URLRequest, jurisdiction: String, completion: @escaping (Result<Void, Error>) -> Void) -> URLSessionDataTask {
        return URLSession.shared.dataTask(with: gameLauncherRequest) { (data: Data?, _, error) in
            if let error = error {
                return completion(.failure(error))
            }

            guard
                let parsedData = data,
                let json = try? JSONSerialization.jsonObject(with: parsedData, options: []) as? [String: Any],
                let ticket = json["ticket"],
                let clientMode = json["clientMode"],
                let currency = json["currency"],
                let locale = json["locale"],
                let country = json["country"]
                else {
                    completion(.failure(KRCError.invalidGameLauncherResponse(data)))
                    return
            }

            let loginJS = """
            window._rcConfig = {...window._rcConfig, ticket: "\(ticket)", clientMode: "\(clientMode)", currency: "\(currency)", jurisdiction: "\(jurisdiction)", locale: "\(locale)", country: "\(country)"};
            window.__AUTH_BY_TICKET__(window.__KRC_REDUX_STORE__.dispatch, `${window.__API_HOST__}/api/v1/auth`);
            window.__APP_JURISDICTION__ = '\(jurisdiction)';
            loadUKFooter();
            """
            self.insertJS(js: loginJS) { result in
                switch result {
                case .success:
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func resolveBuildRegion(for jurisdiction: String) -> String {
        switch jurisdiction {
        case "AU", "NT":
            return "AU"
        default:
            return "UK"
        }
    }

    private func resolveRSAHost(for jurisdiction: String, environment: KRCEnvironment) -> String {
        switch jurisdiction {
        case "AU", "NT":
            return "rsa\(environment.domainComponent).unibet.com.au"
        default:
            return "rsa\(environment.domainComponent).unibet.co.uk"
        }
    }

    private func injectEnvironmentVariables(_ completion: @escaping (Result<Void, Error>) -> Void) {
        /// Decide the api server url
        let envJS = """
        window.__BUILD_REGION__ = '\(resolveBuildRegion(for: jurisdiction))';
        window.__API_HOST__ = 'https://\(resolveRSAHost(for: jurisdiction, environment: environment))';
        window.__GRAPHQL_HOST__ = 'https://\(resolveRSAHost(for: jurisdiction, environment: environment))/api/v1/graphql';
        window._rcConfig = {elementToRenderIn: 'krc-container', clientMode: "mobile", jurisdiction: "\(jurisdiction)", locale: "\(locale)"};
        window.__APP_JURISDICTION__ = '\(jurisdiction)'
        """

        self.insertJS(js: envJS) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func insertJS(js: String, completionHandler: ((Result<Any?, Error>) -> Void)? = nil) {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: { res, error in
                if let error = error {
                    completionHandler?(.failure(error))
                } else {
                    completionHandler?(.success(res))
                }
            })
        }
    }

    private func loadStaticPage() {
        guard
            let htmlPath = Bundle(for: KRCViewController.self).path(forResource: "web/index", ofType: "html")
            else { fatalError("Resources missing in bundle") }

        webView.load(URLRequest(url: URL(fileURLWithPath: htmlPath)))
    }

    private func navigateToURL(hashString: String, completionHandler: ((Result<Any?, Error>) -> Void)?) {
        guard isViewLoaded && !webView.isLoading else {
            completionHandler?(.failure(KRCError.webViewNotReady))
            return
        }

        let navigateJS = """
        window.location.hash = '\(hashString)';
        """
        self.insertJS(js: navigateJS, completionHandler: completionHandler)
    }
}

extension KRCViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case KRCMessageHandler.login.rawValue:
            delegate?.racingClientDidRequestLogin(self)
        case KRCMessageHandler.logout.rawValue,
             KRCMessageHandler.timeout.rawValue:
            delegate?.racingClientDidLogout(self)
        case KRCMessageHandler.sports.rawValue:
            delegate?.racingClientDidRequestNavigationToHome(self)
        case KRCMessageHandler.externalURL.rawValue:
            if let url = URL(string: "\(message.body)") {
                delegate?.racingClient(self, didRequestNavigationToExternalURL: url)
            } else {
                delegate?.racingClient(self, didReceiveUnhandledMessage: "\(message.body)")
            }
        default:
            delegate?.racingClient(self, didReceiveUnhandledMessage: "\(message.body)")
        }
    }
}
