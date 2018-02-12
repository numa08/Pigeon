//
//  GoogleCalendarProviderRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import RxSwift
import GoogleSignIn
import GoogleAPIClientForREST

private extension Notification.Name {
    static let didiSignInGoogleNotification = Notification.Name("didSignInGoogleCalendar")
}

enum GoogleCalendarProviderRepositoryError: Error {
    case faildLoginError()
    case unknownResponseError()
}

class GoogleCalendarProviderRepository: NSObject, ProviderRepository {
    
    let gidSignin: GIDSignIn
    let userDefaults: UserDefaults
    
    init(gidSignin: GIDSignIn, userDefaults: UserDefaults) {
        self.gidSignin = gidSignin
        self.userDefaults = userDefaults
    }
    
    var calendarRepository: [CalendarRepository] {
        get {
            let userIdentifiers = userDefaults.stringArray(forKey: "google_users") ?? []
            let calendars = userIdentifiers.map({identifier -> GoogleCalendarRepository in
                guard let data = self.userDefaults.data(forKey: identifier),
                let user = NSKeyedUnarchiver.unarchiveObject(with: data) as? GIDGoogleUser else {
                    fatalError("")
                }
                guard let colorData = self.userDefaults.data(forKey: "\(user.userID).color"),
                    let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? GTLRCalendar_Colors else {
                        fatalError()
                }
                return GoogleCalendarRepository(userDefaults: self.userDefaults, googleUser: user, colors: color)
            })
            return calendars
        }
    }
    
    func login() -> Observable<Void> {
        if let _ = gidSignin.currentUser {
            gidSignin.signOut()
        }
        gidSignin.delegate = self
        gidSignin.uiDelegate = self
        gidSignin.scopes = [kGTLRAuthScopeCalendar]
        return Observable.create { (completion) -> Disposable in
            // delegate でのサインイン成功/失敗通知を Notification で受け取る
            let center = NotificationCenter.default
            var observer: Any? = nil
            observer = center.addObserver(forName: .didiSignInGoogleNotification, object: nil, queue: nil, using: {notif in
                center.removeObserver(observer!)
                if let error = notif.userInfo?["error"] as? Error {
                    completion.onError(error)
                    return
                }
                guard let user = notif.userInfo?["user"] as? GIDGoogleUser else {
                    completion.onError(GoogleCalendarProviderRepositoryError.faildLoginError())
                    return
                }
                let query = GTLRCalendarQuery_ColorsGet.query()
                let service = GTLRCalendarService()
                service.authorizer = user.authentication.fetcherAuthorizer()
                service.executeQuery(query) {(_, response, error) in
                    if let error = error {
                        completion.onError(error)
                    }
                    guard let colors = response as? GTLRCalendar_Colors else {
                        completion.onError(GoogleCalendarProviderRepositoryError.unknownResponseError())
                        return
                    }
                    self.store(user: user, andColor: colors)
                    completion.onNext(())
                }
            })
            self.gidSignin.signIn()
            return Disposables.create()
        }
    }
    
    func refresh() -> Completable {
        // 色の再取得をやる
        return Completable.create(subscribe: {
            $0(.completed)
            return Disposables.create()
        })
    }
    
    func store(user: GIDGoogleUser, andColor color: GTLRCalendar_Colors) {
        let userData = NSKeyedArchiver.archivedData(withRootObject: user)
        let userIdentifier = "\(user.userID).account"
        userDefaults.set(userData, forKey: userIdentifier)
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        let colorIdentifier = "\(user.userID).color"
        userDefaults.set(colorData, forKey: colorIdentifier)
        // 保存しているユーザー一覧へ追加する
        var users = userDefaults.stringArray(forKey: "google_users") ?? []
        users.append(userIdentifier)
        userDefaults.set(users, forKey: "google_users")
    }
}

extension GoogleCalendarProviderRepository: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        var userInfo: [String: Any] = [:]
        if  let error = error {
            userInfo["error"] = error
        }
        if let user = user {
            userInfo["user"] = user
        }
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        // hack!!
        (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController?.present(viewController, animated: true)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true)
    }
}
