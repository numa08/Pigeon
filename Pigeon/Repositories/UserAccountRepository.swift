//
//  AccountRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import Foundation
import GoogleSignIn

protocol UserAccount: PersistenceModel, CalendarProvider {
    var provider: SupportedProvider { get }
    var identifier: String { get }
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
    
    func store(account: UserAccount, completion: @escaping (Error?) -> Void) 
    func restore(_ completion: @escaping ([UserAccount], Error?) -> Void)
}

struct UserDefaultsUserAccountRepository: UserAccountRepository {
        
    let userDefaults: UserDefaults
    
    func store(account: UserAccount, completion: @escaping (Error?) -> Void) {
        guard let model = account as? UserDefaultsStorableModel else {
            completion(nil)
            return
        }
        let accountIdentifier = "\(account.provider):\(account.identifier)"
        model.store(toUserDefaults: userDefaults, forKey: accountIdentifier)
        var accounts = userDefaults.stringArray(forKey: "userAccounts") ?? []
        if !accounts.contains(accountIdentifier) {
            accounts.append(accountIdentifier)
        }
        userDefaults.set(accounts, forKey: "userAccounts")
        userDefaults.set(account.provider.rawValue, forKey: "\(accountIdentifier):provider")
        userDefaults.synchronize()
        completion(nil)
    }
    
    func restore(_ completion: @escaping ([UserAccount], Error?) -> Void) {
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
        completion(accounts, nil)
    }
}
