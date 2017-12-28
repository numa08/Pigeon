//
//  LoginViewController+GoogleCalendar.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

private extension Notification.Name {
    static let didiSignInGoogleNotification = Notification.Name("didSignInGoogleCalendar")
}

extension LoginViewController {
    
    func requestAccessGoogleCalendar(_ completion: @escaping (UserAccount? ,Error?) -> Void) {
        guard let googleSignIn = GIDSignIn.sharedInstance() else {
            fatalError("fatal GIDSignIn instantiate")
        }
        if googleSignIn.currentUser != nil {
            googleSignIn.signOut()
        }
        googleSignIn.delegate = self
        googleSignIn.uiDelegate = self
        googleSignIn.scopes = [kGTLRAuthScopeCalendar]
        // delegate でのサインイン成功/失敗通知を Notification で受け取る
        let center = NotificationCenter.default
        var observer: Any? = nil
        observer = center.addObserver(forName: .didiSignInGoogleNotification, object: nil, queue: nil, using: {notif in
            center.removeObserver(observer!)
            if let error = notif.userInfo?["error"] as? Error {
                completion(nil, error)
                return
            }
            if let user = notif.userInfo?["user"] as? GIDGoogleUser {
                completion(GoogleAccount(user: user), nil)
            }
        })
        googleSignIn.signIn()
    }
    
}

extension LoginViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        var userInfo: [String: Any] = [:]
        if  let error = error {
            userInfo["error"] = error
        }
        if let user = user {
            userInfo["user"] = user
        }
        NotificationCenter.default.post(name: .didiSignInGoogleNotification, object: nil, userInfo: userInfo)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        fatalError("disconnect処理は実装していない")
    }
    
}
