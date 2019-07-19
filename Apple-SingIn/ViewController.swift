//
//  ViewController.swift
//  Apple-SingIn
//
//  Created by Rohit Singh on 7/19/19.
//  Copyright © 2019 Personal. All rights reserved.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController, ASAuthorizationControllerDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        createAddAppleButton()
        addObserverForAppleIdPasswordChange()
    }
    
    func addObserverForAppleIdPasswordChange() {
        NotificationCenter.default.addObserver(self, selector: #selector(addObserverForAppleIdCredentialsUpdate), name: NSNotification.Name.ASAuthorizationAppleIDProviderCredentialRevoked, object: nil)
    }
    
    @objc fileprivate func addObserverForAppleIdCredentialsUpdate() {
        let provider = ASAuthorizationAppleIDProvider()
        if let userId = UserDefaults.standard.value(forKey: "userId") as? String {
            provider.getCredentialState(forUserID: userId) { (state, error) in
                switch state {
                case .authorized:
                    print("Authorized")
                case .revoked:
                    print("Revoked")
                case .notFound:
                    print("Not found")
                @unknown default:
                    fatalError()
                }
            }

        }
    }
    
    fileprivate func createAddAppleButton() {
        let button = ASAuthorizationAppleIDButton()
        button.addTarget(self, action: #selector(tapAppleSingInButton), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
    
    @objc fileprivate func tapAppleSingInButton() {
        print("Apple Sign In Button has been clicked")
        let requestAppleId = ASAuthorizationAppleIDProvider().createRequest()
        let requestKeychainPassword = ASAuthorizationAppleIDProvider().createRequest()
        requestAppleId.requestedScopes = [.fullName, .email]
        requestKeychainPassword.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [requestAppleId, requestKeychainPassword])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            var message = String()
            if let email = credentials.email {
                message += email
            }
            if let fullName = credentials.fullName,
                let givenName = fullName.givenName,
            let familyName = fullName.familyName {
                message +=  "-" + givenName
                message +=  "-" + familyName
            }
            UserDefaults.standard.set(credentials.user, forKey: "userId")
            UserDefaults.standard.synchronize()
            message += "-" + credentials.user
            print(credentials.user)
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(message: message)
            }
        case let credential as ASPasswordCredential:
            print("User Id: " + credential.user)
            print("Password: " + credential.password)
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(message: credential.user)
            }
        default:
            break
        }
    
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Apple User's details", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    
    //For present window
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
}

