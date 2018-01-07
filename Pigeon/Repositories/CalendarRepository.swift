//
//  CalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import EventKit
import GoogleSignIn
import GoogleAPIClientForREST
import Hydra

extension EKEventStore {
    
    static var shared: EKEventStore = {
       return EKEventStore()
    }()
    
}

protocol Calendar: PersistenceModel, EventHogeHoge {
    var provider: SupportedProvider { get }
    var identifier: String { get }
    var account: UserAccount { get }
}

// Calendar プロトコルは Hashable を実装できないのでラッパーを作る
struct CalendarValue {
    let calendar: Calendar
}

extension CalendarValue: Hashable {
    
    var hashValue: Int {
        get {
            return calendar.identifier.hashValue
        }
    }
    
    static func==(rhs: CalendarValue, lhs: CalendarValue) -> Bool {
        return rhs.calendar.identifier == lhs.calendar.identifier &&
            rhs.calendar.provider == lhs.calendar.provider
    }
    
}

extension Calendar {
    
    func toValue() -> CalendarValue {
        return CalendarValue(calendar: self)
    }
    
}

struct EventKitCalendar : Calendar {
    let provider: SupportedProvider = .EventKit
    var identifier: String {
        get {
            return calendar.calendarIdentifier
        }
    }
    let calendar: EKCalendar
    let account: UserAccount
    
}

extension EventKitCalendar: UserDefaultsStorableModel {
    func store(toUserDefaults userDefaults: UserDefaults, forKey key: String) {
        userDefaults.set(calendar.calendarIdentifier, forKey: key)
    }
 
    init?(userDefaults: UserDefaults, modelIdentifier identifier: String, withUserAccount account: UserAccount) {
        guard let calendarIdentifier = userDefaults.string(forKey: identifier),
            let calendar = EKEventStore.shared.calendars(for: .event).filter({$0.calendarIdentifier == calendarIdentifier}).first else {
            return nil
        }
        self.calendar = calendar
        self.account = account
    }
}

struct GoogleCalendar: Calendar {
    let provider: SupportedProvider = .Google
    let calendar: GTLRCalendar_CalendarListEntry
    let account: UserAccount
    var identifier: String {
        get {
            return "\(account.identifier)/\(calendar.identifier!)"
        }
    }
}

extension GoogleCalendar: NSCodingStorableModel {
    var persistanceDate: NSCoding {
        get {
            return self.calendar
        }
    }
    
    init?(userDefaults: UserDefaults, modelIdentifier identifier: String, withUserAccount account: UserAccount) {
        guard let model = userDefaults.data(forKey: identifier),
            let calendar = NSKeyedUnarchiver.unarchiveObject(with: model) as? GTLRCalendar_CalendarListEntry else {
                return nil
        }
        self.account = account
        self.calendar = calendar
    }
}

protocol CalendarProvider {
    func fetchModifiableCalendar() -> Promise<[Calendar]>
}

extension EventKitAccount: CalendarProvider {
    
    func fetchModifiableCalendar() -> Promise<[Calendar]> {
        return Promise(in: .background) {(resolve, reject, _) in
            let eventStore = EKEventStore.shared
            let list = eventStore.calendars(for: .event).filter({ $0.allowsContentModifications }).map({ EventKitCalendar(calendar: $0, account: self) })
            resolve(list)
        }
    }
    
}

extension GoogleAccount: CalendarProvider {
    
    func fetchModifiableCalendar() -> Promise<[Calendar]> {
        return Promise(in: .background) {(resolve, reject, _) in
            let service = GTLRCalendarService()
            service.authorizer = self.user.authentication.fetcherAuthorizer()
            let query = GTLRCalendarQuery_CalendarListList.query()
            query.minAccessRole = "writer"
            service.executeQuery(query) {(_, response, error) in
                guard let list = response as? GTLRCalendar_CalendarList,
                    let entries = list.items else {
                        fatalError("unknown response")
                }
                if let error = error {
                    reject(error)
                    return
                }
                let calendars = entries.map({ GoogleCalendar(calendar: $0, account: self) })
                resolve(calendars)
            }
        }
    }
}

protocol CalendarRepository {
    
    func store(calendar: Calendar, fromUserAccount account: UserAccount) -> Promise<Void>
    func restore(forAccount account: UserAccount) -> Promise<[Calendar]>
}

struct UserDefaultsCalendarRepository: CalendarRepository {
    
    let userDefaults: UserDefaults
    
    func store(calendar: Calendar, fromUserAccount account: UserAccount) -> Promise<Void> {
        return Promise(in: .background) { (resolve, reject, _) in
            guard let model = calendar as? UserDefaultsStorableModel else {
                resolve(())
                return
            }
            let modelIdentifier = "\(calendar.provider):\(calendar.identifier)"
            let accountIdentifier = "\(account.provider):\(account.identifier):calendar"
            let userDefaults = self.userDefaults
            model.store(toUserDefaults: userDefaults, forKey: modelIdentifier)
            var identifiers = userDefaults.stringArray(forKey: accountIdentifier) ?? []
            if !identifiers.contains(modelIdentifier) {
                print("store \(modelIdentifier)")
                identifiers.append(modelIdentifier)
            }
            userDefaults.set(identifiers, forKey: accountIdentifier)
            userDefaults.set(calendar.provider.rawValue, forKey: "\(modelIdentifier):provider")
            userDefaults.synchronize()
            resolve(())
        }
    }
    
    func restore(forAccount account: UserAccount) -> Promise<[Calendar]> {
        return Promise(in: .background) {(resolve, reject, _) in
            let accountIdentifier = "\(account.provider):\(account.identifier):calendar"
            let userDefaults = self.userDefaults
            let modelIdentifiers = userDefaults.stringArray(forKey: accountIdentifier) ?? []
            let calendars: [Calendar] = modelIdentifiers.map({identifier in
                print("restore calendarIdentifier: \(identifier)")
                let providerKey = "\(identifier):provider"
                guard let providerName = userDefaults.string(forKey: providerKey) else {
                    fatalError("provider name is not stored. key: \(providerKey)")
                }
                guard let provider = SupportedProvider(rawValue: providerName) else {
                    fatalError("provider name is invalid. name: \(providerName)")
                }
                let calendar: Calendar = {
                    switch provider {
                    case .EventKit:
                        guard let c = EventKitCalendar(userDefaults: userDefaults, modelIdentifier: identifier, withUserAccount: account) else {
                            fatalError("Failed restore EventKitCalendar. identifier: \(identifier), account: \(account)")
                        }
                        return c
                    case .Google:
                        guard let c = GoogleCalendar(userDefaults: userDefaults, modelIdentifier: identifier, withUserAccount: account) else {
                            fatalError("Failed restore GoogleCalendar. identifier: \(identifier), account: \(account)")
                        }
                        return c
                    }
                }()
                return calendar
            })
            resolve(calendars)
        }
    }
}
