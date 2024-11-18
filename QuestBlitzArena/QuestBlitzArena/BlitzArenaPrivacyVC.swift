//
//  BlitzArenaPrivacyVC.swift
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

import UIKit
@preconcurrency import WebKit

class BlitzArenaPrivacyVC: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    @IBOutlet weak var oxIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var oxWebView: WKWebView!
    @IBOutlet weak var oxBackBtn: UIButton!
    @IBOutlet weak var topCos: NSLayoutConstraint!
    @IBOutlet weak var bottomCos: NSLayoutConstraint!
    
    var backAction: (() -> Void)?
    var confData: [Any]?
    @objc var url: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confData = UserDefaults.standard.array(forKey: UIViewController.getUserDefaultKey())
        blitzInitSubViews()
        blitzInitConfigNav()
        blitzInitWebViewConfig()
        blitzInitWebData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let confData = confData, confData.count > 4 {
            let top = (confData[3] as? Int) ?? 0
            let bottom = (confData[4] as? Int) ?? 0
            
            if top > 0 {
                topCos.constant = view.safeAreaInsets.top
            }
            if bottom > 0 {
                bottomCos.constant = view.safeAreaInsets.bottom
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscape]
    }
    
    @objc func backClick() {
        backAction?()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - INIT
    private func blitzInitSubViews() {
        oxWebView.scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = .black
        oxWebView.backgroundColor = .black
        oxWebView.isOpaque = false
        oxWebView.scrollView.backgroundColor = .black
        oxIndicatorView.hidesWhenStopped = true
    }
    
    private func blitzInitConfigNav() {
        oxBackBtn.isHidden = navigationController == nil
        
        guard let url = url, !url.isEmpty else {
            oxWebView.scrollView.contentInsetAdjustmentBehavior = .automatic
            return
        }
        
        oxBackBtn.isHidden = true
        navigationController?.navigationBar.tintColor = .systemBlue
        
        let image = UIImage(systemName: "xmark")
        let rightButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(backClick))
        navigationItem.rightBarButtonItem = rightButton
    }
    
    private func blitzInitWebViewConfig() {
        guard let confData = confData, confData.count > 7 else { return }
        
        let userContentC = oxWebView.configuration.userContentController
        
        if let trackStr = confData[5] as? String {
            let trackScript = WKUserScript(source: trackStr, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userContentC.addUserScript(trackScript)
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let bundleId = Bundle.main.bundleIdentifier,
           let wgName = confData[7] as? String {
            let inPPStr = "window.\(wgName) = {name: '\(bundleId)', version: '\(version)'}"
            let inPPScript = WKUserScript(source: inPPStr, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userContentC.addUserScript(inPPScript)
        }
        
        if let messageHandlerName = confData[6] as? String {
            userContentC.add(self, name: messageHandlerName)
        }
        
        oxWebView.navigationDelegate = self
        oxWebView.uiDelegate = self
    }
    
    private func blitzInitWebData() {
        let urlStr = url ?? "https://www.termsfeed.com/live/91e5bd7d-8b54-4196-84fb-6abe8066e85b"
        guard let url = URL(string: urlStr) else { return }
        
        oxIndicatorView.startAnimating()
        let request = URLRequest(url: url)
        oxWebView.load(request)
    }
    
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let confData = confData, confData.count > 9 else { return }
        
        let name = message.name
        if name == (confData[6] as? String),
           let trackMessage = message.body as? [String: Any] {
            let tName = trackMessage["name"] as? String ?? ""
            let tData = trackMessage["data"] as? String ?? ""
            if let data = tData.data(using: .utf8) {
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if tName != (confData[8] as? String) {
                            blitzSendEvent(tName, values: jsonObject)
                            return
                        }
                        if tName == (confData[9] as? String) {
                            return
                        }
                        if let adId = jsonObject["url"] as? String, !adId.isEmpty {
                            blitzReloadWebViewData(adId)
                        }
                    }
                } catch {
                    blitzSendEvent(tName, values: [tName: data])
                }
            } else {
                blitzSendEvent(tName, values: [tName: tData])
            }
        }
    }
    
    private func blitzReloadWebViewData(_ adurl: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let storyboard = self.storyboard,
               let adView = storyboard.instantiateViewController(withIdentifier: "BlitzArenaPrivacyVC") as? BlitzArenaPrivacyVC {
                adView.url = adurl
                adView.backAction = { [weak self] in
                    let close = "window.closeGame();"
                    self?.oxWebView.evaluateJavaScript(close, completionHandler: nil)
                }
                let nav = UINavigationController(rootViewController: adView)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.oxIndicatorView.stopAnimating()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.oxIndicatorView.stopAnimating()
        }
    }
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let authenticationMethod = challenge.protectionSpace.authenticationMethod
        if authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        }
    }

}
