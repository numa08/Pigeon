//
//  File.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import RxSwift

protocol GoogleAccountStorageType {
    var accounts: [(GIDGoogleUser, GTLRCalendar_Colors)] { get }
    func refresh() -> Observable<Void>
    func store(user: GIDGoogleUser) -> Observable<Void>
}

struct GoogleAccountStorage: GoogleAccountStorageType {
    
    private enum UserDefaultsKeys: String {
        case GoogleUsers = "google_users"
        case UserIdentifier = "account"
        case CalendarColors = "calendar_colors"
    }
    
    let userDefaults: UserDefaults
    
    var accounts: [(GIDGoogleUser, GTLRCalendar_Colors)] {
        get {
            let users = userDefaults.stringArray(forKey: UserDefaultsKeys.GoogleUsers.rawValue) ?? []
            return users.map { userID -> (GIDGoogleUser, GTLRCalendar_Colors) in
                guard let userData = self.userDefaults.data(forKey: "\(userID).\(UserDefaultsKeys.UserIdentifier)"),
                let user = NSKeyedUnarchiver.unarchiveObject(with: userData) as? GIDGoogleUser,
                let colorData = self.userDefaults.data(forKey: "\(userID).\(UserDefaultsKeys.CalendarColors)"),
                    let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? GTLRCalendar_Colors else {
                        fatalError("failed unarchive from user defaults")
                }
                return (user, color)
            }
        }
    }
    
    func refresh() -> Observable<Void> {
        let observables = accounts.map({args -> Observable<Void> in
            let (user, _) = args
            return self.fetchColors(forUser: user)
            .map({colors -> Void in
                self.store(user: user, andColor: colors)
                return ()
            })
        })
        return Observable<Void>.merge(observables)
    }
    
    func store(user: GIDGoogleUser) -> Observable<Void> {
        return fetchColors(forUser: user)
        .map({colors in
            self.store(user: user, andColor: colors)
            return ()
        })
    }

    private func fetchColors(forUser user: GIDGoogleUser) -> Observable<GTLRCalendar_Colors> {
        return Observable.create({emitter in
            let query = GTLRCalendarQuery_ColorsGet.query()
            let service = GTLRCalendarService()
            service.authorizer = user.authentication.fetcherAuthorizer()
            service.executeQuery(query) {(_, response, error) in
                if let error = error {
                    emitter.onError(error)
                }
                guard let colors = response as? GTLRCalendar_Colors else {
                    emitter.onError(GoogleCalendarProviderRepositoryError.unknownResponseError())
                    return
                }
                emitter.onNext(colors)
            }
            return Disposables.create()
        })
    }
    
    private func store(user: GIDGoogleUser, andColor color: GTLRCalendar_Colors) {
        let userData = NSKeyedArchiver.archivedData(withRootObject: user)
        let userIdentifier = "\(user.userID).\(UserDefaultsKeys.UserIdentifier)"
        userDefaults.set(userData, forKey: userIdentifier)
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        let colorIdentifier = "\(user.userID).\(UserDefaultsKeys.CalendarColors)"
        userDefaults.set(colorData, forKey: colorIdentifier)
        // 保存しているユーザー一覧へ追加する
        var users = userDefaults.stringArray(forKey: UserDefaultsKeys.GoogleUsers.rawValue) ?? []
        users.append(user.userID)
        userDefaults.set(users, forKey: UserDefaultsKeys.GoogleUsers.rawValue)
    }

}
