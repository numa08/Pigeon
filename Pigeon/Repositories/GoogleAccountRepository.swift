//
//  GoogleAccountRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import Foundation
import Google
import GoogleAPIClientForREST
import GoogleSignIn

protocol GoogleAccountRepository {
    var authorizer: GTMFetcherAuthorizationProtocol? { get }
    var scopes: [String] { get }
    func signInSilently()
    func signIn(uiDelegate: GIDSignInUIDelegate, completion: @escaping (Error?) -> Void)
}

private extension Notification.Name {
    static let didSignInNotification = Notification.Name("didSignIn")
}

class DefaultGoogleAccountRepository:NSObject, GoogleAccountRepository {
    
    static let shared: GoogleAccountRepository = {
        return DefaultGoogleAccountRepository()
    }()
    
    private let googleSignIn:GIDSignIn = GIDSignIn.sharedInstance()
    private(set) var authorizer: GTMFetcherAuthorizationProtocol? = nil
    let scopes: [String] = [kGTLRAuthScopeCalendar]
    
    override init() {
        super.init()
        googleSignIn.delegate = self
        googleSignIn.scopes = self.scopes
    }
    
    func signInSilently() {
        googleSignIn.signInSilently()
    }
    
    func signIn(uiDelegate: GIDSignInUIDelegate, completion: @escaping (Error?) -> Void) {
        googleSignIn.uiDelegate = uiDelegate
        let center = NotificationCenter.default
        center.addObserver(forName: .didSignInNotification, object: nil, queue: nil) { notif in
            self.googleSignIn.uiDelegate = nil
            let error = notif.userInfo?["error"] as? Error
            completion(error)
        }
        googleSignIn.signIn()
    }
}

extension DefaultGoogleAccountRepository: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        self.authorizer = user?.authentication?.fetcherAuthorizer()
        var userInfo: [String: Any] = [:]
        if let error = error {
            userInfo["error"] = error
        }
        NotificationCenter.default.post(name: .didSignInNotification, object: nil, userInfo: userInfo)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        
    }
}
