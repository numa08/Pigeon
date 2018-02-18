//
//  File.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import RxSwift
import GoogleSignIn
import GoogleAPIClientForREST
import GTMOAuth2

protocol GoogleAccountStorageType {
    var accounts: Observable<[(GIDGoogleUser, GTLRCalendar_Colors)]> { get }
    func refresh()
    func store(user: GIDGoogleUser)
    func find(forProvider provider: CalendarProviderEntity) -> Observable<GIDGoogleUser?>
}

enum GoogleAccountStorageError: Error {
    case unknownResponseError
}

class GoogleAccountStorage: GoogleAccountStorageType {
    
    private enum UserDefaultsKeys: String {
        case GoogleUsers = "google_users"
        case UserIdentifier = "account"
        case CalendarColors = "calendar_colors"
    }
    
    let userDefaults: UserDefaults
    lazy var accountsSubject : BehaviorSubject<[(GIDGoogleUser, GTLRCalendar_Colors)]> = {
        let subject = BehaviorSubject(value: restore())
        return subject
    }()
    lazy var accounts: Observable<[(GIDGoogleUser, GTLRCalendar_Colors)]> = {
        return accountsSubject.share(replay: 1)
    }()
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    func refresh() {
        let _ = Observable.from(
        restore().map({(user, _) in
            self.fetchColors(forUser: user)
            .map({(user, $0)})
            .do(onNext: {(user, color) in self.store(user: user, andColor: color) })
        })).merge()
        .reduce([], accumulator: {(list, account) -> [(GIDGoogleUser, GTLRCalendar_Colors)] in
            var l = list
            l.append(account)
            return l
        })
        .subscribe(onNext: { accounts in
            self.accountsSubject.onNext(accounts)
        })
    }
    
    func store(user: GIDGoogleUser) {
        let _ = fetchColors(forUser: user)
        .subscribe(onNext: {colors in
            self.store(user: user, andColor: colors)
            self.accountsSubject.onNext(self.restore())
        })
    }

    func restore() -> [(GIDGoogleUser, GTLRCalendar_Colors)] {
        let users = userDefaults.stringArray(forKey: UserDefaultsKeys.GoogleUsers.rawValue) ?? []
        return users.map { userID -> (GIDGoogleUser, GTLRCalendar_Colors) in
            guard let userData = self.userDefaults.data(forKey: "\(userID).\(UserDefaultsKeys.UserIdentifier.rawValue)"),
                let user = NSKeyedUnarchiver.unarchiveObject(with: userData) as? GIDGoogleUser,
                let colorData = self.userDefaults.data(forKey: "\(userID).\(UserDefaultsKeys.CalendarColors.rawValue)"),
                let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? GTLRCalendar_Colors else {
                    fatalError("failed unarchive from user defaults")
            }
            return (user, color)
        }
    }
    
    func fetchColors(forUser user: GIDGoogleUser) -> Observable<GTLRCalendar_Colors> {
        return Observable.create({emitter in
            let query = GTLRCalendarQuery_ColorsGet.query()
            let service = GTLRCalendarService()
            service.authorizer = user.authentication.fetcherAuthorizer()
            service.executeQuery(query) {(_, response, error) in
                if let error = error {
                    emitter.onError(error)
                }
                guard let colors = response as? GTLRCalendar_Colors else {
                    emitter.onError(GoogleAccountStorageError.unknownResponseError)
                    return
                }
                emitter.onNext(colors)
                emitter.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    func find(forProvider provider: CalendarProviderEntity) -> Observable<GIDGoogleUser?> {
        return Observable.create({ (emitter) -> Disposable in
            guard let ownerIdentifier = provider.ownerIdentifier else {
                emitter.onNext(nil)
                emitter.onCompleted()
                return Disposables.create()
            }
            let user = self.restore().first(where: {(user, _) in user.userID == ownerIdentifier.value })?.0
            emitter.onNext(user)
            emitter.onCompleted()
            return Disposables.create()
        })
    }
    
    private func store(user: GIDGoogleUser, andColor color: GTLRCalendar_Colors) {
        let userData = NSKeyedArchiver.archivedData(withRootObject: user)
        let userIdentifier = "\(user.userID!).\(UserDefaultsKeys.UserIdentifier.rawValue)"
        userDefaults.set(userData, forKey: userIdentifier)
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        let colorIdentifier = "\(user.userID!).\(UserDefaultsKeys.CalendarColors.rawValue)"
        userDefaults.set(colorData, forKey: colorIdentifier)
        // 保存しているユーザー一覧へ追加する
        var users = userDefaults.stringArray(forKey: UserDefaultsKeys.GoogleUsers.rawValue) ?? []
        users.append(user.userID!)
        userDefaults.set(users, forKey: UserDefaultsKeys.GoogleUsers.rawValue)
    }

}
