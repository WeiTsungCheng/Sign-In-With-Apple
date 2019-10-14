//
//  ResultViewController.swift
//  signInWithApple
//
//  Created by WEI-TSUNG CHENG on 2019/10/8.
//  Copyright © 2019 WEI-TSUNG CHENG. All rights reserved.
//

import UIKit
import SnapKit

class ResultViewController: UIViewController {
    
    lazy var signOutButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        btn.setTitle("Sign Out", for: .normal)
        btn.addTarget(self, action: #selector(showSignIn), for: .touchUpInside)
        return btn
    }()
    
    lazy var userCredentialLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "UserCredentialLabel:"
        lbl.numberOfLines = 0
        return lbl
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        //  顯示之前存在keyCHain 的 UserIdentifier
        userCredentialLabel.text = KeychainItem.currentUserIdentifier
        print(KeychainItem.currentUserIdentifier)

        setupUI()
       
        DispatchQueue.main.async {
            let vc = ViewController()
            self.present(vc, animated: true, completion: nil)
        }
        
    }
    
    private func setupUI() {
        self.view.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        self.view.addSubview(signOutButton)
        self.view.addSubview(userCredentialLabel)
        
        signOutButton.snp.makeConstraints { maker in
            maker.height.equalTo(80)
            maker.width.equalTo(240)
            maker.centerX.equalToSuperview()
            maker.topMargin.equalToSuperview().offset(50)
        }
        
        userCredentialLabel.snp.makeConstraints { maker in
            maker.height.equalTo(80)
            maker.width.equalTo(240)
            maker.centerX.equalToSuperview()
            maker.topMargin.equalToSuperview().offset(120)
        }
    }
    
    @objc private func showSignIn() {
        // 清除label 顯示的UserIdentifier
        userCredentialLabel.text = ""
        // 清除keyChain上的UserIdentifier
        KeychainItem.deleteUserIdentifierFromKeychain()
        let vc = ViewController()
        present(vc, animated: true, completion: nil)
    }
    
    
}
