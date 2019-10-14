//
//  ViewController.swift
//  signInWithApple
//
//  Created by WEI-TSUNG CHENG on 2019/10/4.
//  Copyright © 2019 WEI-TSUNG CHENG. All rights reserved.
//

import UIKit
import SnapKit
import AuthenticationServices

class ViewController: UIViewController {
    
    private lazy var loginBtn: ASAuthorizationAppleIDButton = {
        var btn = ASAuthorizationAppleIDButton()
        btn.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addObserverForAppleIDChangeNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlow()
    }
    
    private func setupUI() {
        self.view.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        self.view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { maker in
            maker.width.equalTo(240)
            maker.centerX.equalToSuperview()
            maker.topMargin.equalToSuperview().offset(50)
        }
    }
    
    @objc private func appleSignInTapped() {
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        // 這裏可以選擇需要輸入的資料
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        // 決定誰來呈現畫面 (這裏指定給當前的VC)
        controller.presentationContextProvider = self
        
        // 開始執行請求
        controller.performRequests()
    }
    
    private func addObserverForAppleIDChangeNotification() {
        
        let notificationName: Notification.Name = ASAuthorizationAppleIDProvider.credentialRevokedNotification
        NotificationCenter.default.addObserver(self, selector: #selector(appliedStateChanged), name: notificationName, object: nil)
    }
    
    @objc private func appliedStateChanged() {
        let provider = ASAuthorizationAppleIDProvider()
        
        // 從keyChain 把sign in with apple 儲存的 userID 取出, 查看該用戶的CredentialState
        let appleUserID: String = KeychainItem.currentUserIdentifier
        print("tUserIdentifier load from")
        
        // forUserID 為成功登入時獲得的user資訊
        provider.getCredentialState(forUserID: appleUserID) { (credentialState, error) in
            
            switch credentialState {
            case .authorized:
                print("🔵authorized")
                // 用戶獲得授權
                // 正常使用
                break
            case .notFound:
                print("🔴notFound")
                // 用戶無法找到
                // 登出
                break
            case .revoked:
                print("🔴revoked")
                self.view.backgroundColor = UIColor.green
                // 授權被撤銷
                // 登出
                break
            case .transferred:
                print("🔶transferred")
                break
            @unknown default:
                break
            }
        }
        
    }
    
    // 如果曾經執行過sign In with apple 則可以直接啟動apple sign In 的程序, 直接透過 touch ID 或 faceID 去做認證
    // 如果之前有帳密是依附在keyChain 上的, 則ASPasswordCredential 可以提供過去的路去signIn
    private func performExistingAccountSetupFlow() {
        
        let requests = [ASAuthorizationPasswordProvider().createRequest(),
                        ASAuthorizationAppleIDProvider().createRequest()]
        // 注意! 這裡與第一次登入不同, 不要求提供email fullName
        // 如果沒登入過則request失效, 進入ASAuthorizationControllerDelegate 中的  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
}


extension ViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            let userCredential = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email: String = appleIDCredential.email ?? ""
            
            let identityTokenData: Data? = appleIDCredential.identityToken ?? nil
            let identityTokenString: String = String(data: identityTokenData!, encoding: String.Encoding.utf8) ?? ""
            
            let authorizationCode: Data? = appleIDCredential.authorizationCode ?? nil
            let authorizationCodeString: String = String(data: authorizationCode!, encoding: String.Encoding.utf8) ?? ""
            
            let detectionStatus: ASUserDetectionStatus = appleIDCredential.realUserStatus
            var status: String?
            switch detectionStatus {
            case .likelyReal:
                status = "likelyReal"
            case .unknown:
                status = "unknown"
            case .unsupported:
                status = "unsupported"
            default:
                break
            }
            
            // 這裏可以將獲得到的name, email, userCredential, 作為系統的帳密
            print("""
                SignIn with Apple ID Credential
                💳 userCredential: \(userCredential)
                👦 fullName: \(String(describing: fullName))
                ✉️ email: \(String(describing: email))
                🎫 token: \(String(describing: identityTokenString))
                🎟 authorizationCode: \(String(describing: authorizationCodeString))
                🧟‍♂️ detectionStatus: \(String(describing: status))
                """)
            
            // 這裡置只先存在keyChain中, 方便取用, 實際使用不一定需要
            do {
                try KeychainItem(service: "WeiTsungCheng.signInWithApple1987", account: "userCredential").saveItem(userCredential)
            } catch {
                print("Unable to save userCredential to keychain")
            }
            
            if let presentingViewController = self.presentingViewController as? ResultViewController {
                DispatchQueue.main.async {
                    presentingViewController.userCredentialLabel.text =  "UserCredential: \(userCredential)"
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        } else if let passwordCredentail = authorization.credential as? ASPasswordCredential {
            // ASAuthorizationPasswordProvider().createRequest() 表示用戶已經登入過，keyChain 已經有除儲存的密碼, 則可以用keyChain 已儲存的密碼
            
            let username = passwordCredentail.user
            let password = passwordCredentail.password
            
            DispatchQueue.main.async {
                let message = "Received selected credential from Keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                
                // 這裡可以走原先存keyChain password的方式(有password的方式)登入
            }
            
            
            
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
    
}


extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 回傳當前VC view 所在的window
        return self.view.window!
    }
    
    
}
