//
//  LoginViewController+GoogleCalendar.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import GoogleAPIClientForREST
import GoogleSignIn
import UIKit

extension LoginViewController: GIDSignInUIDelegate, GIDSignInDelegate {
    func loginToGoogle() {
        let signin = GIDSignIn.sharedInstance()!
        if let _ = signin.currentUser {
            signin.signOut()
        }
        signin.delegate = self
        signin.uiDelegate = self
        signin.scopes = [kGTLRAuthScopeCalendar]
        signin.signIn()
    }

    func sign(_: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            onLoginGoogle.onError(error)
            return
        }
        if let user = user {
            onLoginGoogle.onNext(user)
        }
    }
}
