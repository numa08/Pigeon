//
//  GoogleCalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import GTMOAuth2
import RxSwift

struct GoogleCalendarRepository: CalendarRepositoryType {
    
    
    let accountStorage: GoogleAccountStorage
    let googleService: () -> GTLRCalendarService
    let userDefaults: UserDefaults
    
    
    var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> {
        get {
            return Observable.create({ (emitter) -> Disposable in
                let entities = self.accountStorage.accounts.map({ (user, colors) -> (CalendarProviderEntity, [CalendarEntity]) in
                    let identifiers = self.userDefaults.stringArray(forKey: "\(user.userID).\(UserDefaultsKeys.CalendarIdentifier.rawValue)") ?? []
                    let calendars = identifiers.map({ (identifier) -> GTLRCalendar_CalendarListEntry? in
                        guard let data = self.userDefaults.data(forKey: identifier),
                            let entry = NSKeyedUnarchiver.unarchiveObject(with: data) as? GTLRCalendar_CalendarListEntry else {
                                emitter.onError(Errors.InvalidObjectStoredError)
                                return nil
                        }
                        return entry
                    }).filter({ $0 != nil }).map { $0! }
                        .map({ (entry) -> CalendarEntity in
                            let colorId = entry.colorId ?? ""
                            let colors = colors.calendar?.jsonValue(forKey: colorId) as? [String: String]
                            let color = colors?["background"]
                            let hex = color?.replacingOccurrences(of: "#", with: "") ?? ""
                            let uiColor = UIColor(hex: hex) ?? UIColor.clear
                            return CalendarEntity(id: CalendarEntityId(value: entry.identifier!), title: entry.summary!, detail: "", color: uiColor)
                        })
                    let provider = CalendarProviderEntity(name: user.profile.email)
                    return (provider, calendars)
                }).flatMap { $0 }
                emitter.onNext(entities)
                return Disposables.create()
            })
        }
    }

    enum Errors: Error {
        case InvalidResponseError
        case InvalidObjectStoredError
    }
    enum UserDefaultsKeys: String {
        case CalendarIdentifier = "calenars"
    }
    
    func refresh() -> Observable<Void> {
        let observables = accountStorage.accounts.map { (user, _) -> Observable<Void> in
            return Observable.create({ (emitter) -> Disposable in
                let service = self.googleService()
                service.authorizer = user.authentication.fetcherAuthorizer()
                let query = GTLRCalendarQuery_CalendarListList.query()
                query.minAccessRole = "writer"
                service.executeQuery(query, completionHandler: { (_, response, error) in
                    if let error = error {
                        emitter.onError(error)
                        return
                    }
                    guard let response = response as? GTLRCalendar_CalendarList,
                        let entries = response.items else {
                            emitter.onError(Errors.InvalidResponseError)
                            return
                    }
                    let identifiers = entries.map({ (entry) -> String in
                        let data = NSKeyedArchiver.archivedData(withRootObject: entry)
                        let identifier = "\(user.userID).calendars.\(entry.identifier!)"
                        self.userDefaults.set(data, forKey: identifier)
                        return identifier
                    })
                    let accountIdentifier = "\(user.userID).\(UserDefaultsKeys.CalendarIdentifier.rawValue)"
                    self.userDefaults.set(identifiers, forKey: accountIdentifier)
                    emitter.onNext(())
                })
                return Disposables.create()
            })
        }
        return Observable.merge(observables)
    }
    
}
