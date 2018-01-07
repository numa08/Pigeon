//
//  AccountRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import Foundation
import GoogleSignIn
import Hydra

protocol UserAccount: PersistenceModel, CalendarProvider {
    var provider: SupportedProvider { get }
    var identifier: String { get }
}

struct UserAccountValue {
    let userAccount: UserAccount
}

extension UserAccountValue: Hashable {
    
    var hashValue: Int {
        get {
            return userAccount.identifier.hashValue
        }
    }
    
    static func ==(rhs: UserAccountValue, lhs: UserAccountValue) -> Bool {
        return rhs.userAccount.identifier == lhs.userAccount.identifier &&
            rhs.userAccount.provider == lhs.userAccount.provider
    }

}

extension UserAccount {
    func toValue() -> UserAccountValue {
        return UserAccountValue(userAccount: self)
    }
}

struct EventKitAccount : UserAccount {
    let identifier: String = "eventKit"
    let provider: SupportedProvider = .EventKit
}

extension EventKitAccount: UserDefaultsStorableModel {
    func store(toUserDefaults userDefaults: UserDefaults, forKey key: String) {
        userDefaults.set(true, forKey: key)
    }
}

struct GoogleAccount: UserAccount {
    let provider: SupportedProvider = .Google
    let user: GIDGoogleUser
    var identifier: String {
        get {
            return user.userID
        }
    }
    init(user: GIDGoogleUser) {
        self.user = user
    }
}

extension GoogleAccount: NSCodingStorableModel {
    init?(userDefaults: UserDefaults, modelIdentifier identifier: String) {
        guard let model = userDefaults.data(forKey: identifier),
            let user = NSKeyedUnarchiver.unarchiveObject(with: model) as? GIDGoogleUser else {
                return nil
        }
        self.user = user
    }
    
    var persistanceDate: NSCoding {
        get {
            return self.user
        }
    }
}

protocol UserAccountRepository {
    
    func store(account: UserAccount) -> Promise<Void>
    func restore() -> Promise<[UserAccount]>
}

struct UserDefaultsUserAccountRepository: UserAccountRepository {
        
    let userDefaults: UserDefaults
    
    func restore() -> Promise<[UserAccount]> {
        return Promise(in: .background, { (resolve, rejet, _) in
            let userDefaults = self.userDefaults
            let accountIdentifiers = userDefaults.stringArray(forKey: "userAccounts") ?? []
            let accounts: [UserAccount] = accountIdentifiers.map({identifier in
                let providerKey = "\(identifier):provider"
                guard let providerName = userDefaults.string(forKey: providerKey) else {
                    fatalError("provider name is not stored. key: \(providerKey)")
                }
                guard let provider = SupportedProvider(rawValue: providerName) else {
                    fatalError("provider name is invalid. name: \(providerName)")
                }
                let account: UserAccount = {
                    switch provider {
                    case .EventKit:
                        return EventKitAccount()
                    case .Google:
                        guard let a = GoogleAccount(userDefaults: userDefaults, modelIdentifier: identifier) else {
                            fatalError("Failed restore GoogleAccount. identifier: \(identifier)")
                        }
                        return a
                    }
                }()
                return account
            })
            resolve(accounts)
        })
    }
    
    func store(account: UserAccount) -> Promise<Void> {
        return Promise(in: .background, { (resolve, reject, _) in
            guard let model = account as? UserDefaultsStorableModel else {
                
                return
            }
            let userDefaults = self.userDefaults
            let accountIdentifier = "\(account.provider):\(account.identifier)"
            model.store(toUserDefaults: userDefaults, forKey: accountIdentifier)
            var accounts = userDefaults.stringArray(forKey: "userAccounts") ?? []
            if !accounts.contains(accountIdentifier) {
                accounts.append(accountIdentifier)
            }
            userDefaults.set(accounts, forKey: "userAccounts")
            userDefaults.set(account.provider.rawValue, forKey: "\(accountIdentifier):provider")
            userDefaults.synchronize()
            resolve(())
        })
    }
    
}
