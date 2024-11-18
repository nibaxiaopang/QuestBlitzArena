//
//  BlitzArenaStartController.swift
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

import UIKit

class BlitzArenaStartController: UIViewController {
    
    @IBOutlet weak var oxKineAdsActivityView: UIActivityIndicatorView!
    @IBOutlet weak var startView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.oxKineAdsActivityView.hidesWhenStopped = true
        self.blitzReqAdsLocalData()
    }

    private func blitzReqAdsLocalData() {
        guard self.blitzNeedShowAds() else {
            return
        }
        self.startView.isHidden = true
        self.oxKineAdsActivityView.startAnimating()
        blitzLocalAdsData { adsData in
            if let adsData = adsData {
                if let adsUr = adsData[2] as? String, !adsUr.isEmpty,  let nede = adsData[1] as? Int, let userDefaultKey = adsData[0] as? String{
                    UIViewController.setUserDefaultKey(userDefaultKey)
                    if  nede == 0, let locDic = UserDefaults.standard.value(forKey: userDefaultKey) as? [Any] {
                        self.blitzShowAdViewC(locDic[2] as! String)
                    } else {
                        UserDefaults.standard.set(adsData, forKey: userDefaultKey)
                        self.blitzShowAdViewC(adsUr)
                    }
                    return
                }
            }
            self.oxKineAdsActivityView.stopAnimating()
            self.startView.isHidden = false
        }
    }
    
    private func blitzLocalAdsData(completion: @escaping ([Any]?) -> Void) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            completion(nil)
            return
        }
        
        let url = URL(string: "https://op\(self.oxKineHostUrl())/open/blitzLocalAdsData")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters: [String: Any] = [
            "localizedModel": UIDevice.current.localizedModel ,
            "appModelName": UIDevice.current.model,
            "appKey": "0a993b7b3daf49788777e172e5d5c672",
            "appPackageId": bundleId,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Failed to serialize JSON:", error)
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Request error:", error ?? "Unknown error")
                    completion(nil)
                    return
                }
                
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    if let resDic = jsonResponse as? [String: Any] {
                        if let dataDic = resDic["data"] as? [String: Any],  let adsData = dataDic["jsonObject"] as? [Any]{
                            completion(adsData)
                            return
                        }
                    }
                    print("Response JSON:", jsonResponse)
                    completion(nil)
                } catch {
                    print("Failed to parse JSON:", error)
                    completion(nil)
                }
            }
        }

        task.resume()
    }

}
