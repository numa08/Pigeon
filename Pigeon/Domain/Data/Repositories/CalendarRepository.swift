//
//  CalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import RxSwift
import EventKit
import GoogleSignIn
import GTMSessionFetcher
import GoogleAPIClientForREST

protocol CalendarRepository {
    var providerName: String { get }
    var calendars: Single<[CalendarEntity]> { get }
    func refresh() -> Completable
}

struct EventKitCalendarRepository: CalendarRepository {
    
    let eventStore: EKEventStore
    
    var providerName: String {
        get {
            return "iOS"
        }
    }
    
    var calendars: Single<[CalendarEntity]> {
        get {
            return Single.create { (emitter) -> Disposable in
                let calendars = self
                    .eventStore
                    .calendars(for: .event)
                    .filter({ $0.allowsContentModifications })
                    .map({ c -> CalendarEntity in
                        return CalendarEntity(
                            id: CalendarEntityId(value: c.calendarIdentifier),
                            title: c.title,
                            detail: c.source.title,
                            color: UIColor(cgColor: c.cgColor)
                        )
                    })
                emitter(.success(calendars))
                return Disposables.create()
            }
        }
    }

    func refresh() -> Completable {
        return Completable.create { (emitter) -> Disposable in
            emitter(.completed)
            return Disposables.create()
        }
    }
    
}

enum GoogleCalendarRepositoryError: Error {
    case InvalidResponseError
    case StoredDataStateError
}
struct GoogleCalendarRepository: CalendarRepository {
    
    let userDefaults: UserDefaults
    let googleService: GTLRCalendarService
    let googleUser: GIDGoogleUser
    let colors: GTLRCalendar_Colors
    
    init(
        userDefaults: UserDefaults,
        googleUser: GIDGoogleUser,
        colors: GTLRCalendar_Colors) {
        self.userDefaults = userDefaults
        self.googleService = GTLRCalendarService()
        self.googleUser = googleUser
        self.googleService.authorizer = self.googleUser.authentication.fetcherAuthorizer()
        self.colors = colors
    }
    
    var providerName: String {
        get {
            return self.googleUser.profile.email
        }
    }
    
    var calendars: Single<[CalendarEntity]> {
        get {
            let identifiers = "\(self.googleUser.userID!).calendars"
            return Single.create { (emitter) -> Disposable in
                let identifiers = self.userDefaults.stringArray(forKey: identifiers) ?? []
                let entities = identifiers.map({ (id) -> GTLRCalendar_CalendarListEntry in
                    guard let data = self.userDefaults.data(forKey: id),
                          let entry = NSKeyedUnarchiver.unarchiveObject(with: data) as? GTLRCalendar_CalendarListEntry
                    else {
                        emitter(.error(GoogleCalendarRepositoryError.StoredDataStateError))
                        fatalError()
                    }
                    return entry
                }).map({ (entry) -> CalendarEntity in
                    let colorId = entry.colorId ?? ""
                    let colors = self.colors.calendar?.jsonValue(forKey: colorId) as? [String: String]
                    let color = colors?["background"]
                    let hex = color?.replacingOccurrences(of: "#", with: "") ?? ""
                    let uiColor = UIColor(hex: hex) ?? UIColor.clear
                    return CalendarEntity(
                        id: CalendarEntityId(value: entry.identifier!),
                        title: entry.summary!,
                        detail: "",
                        color: uiColor)
                })
                emitter(.success(entities))
                
                return Disposables.create()
            }
        }
    }
    
    func refresh() -> Completable {
        return Completable.create(subscribe: { (emitter) -> Disposable in
            let query = GTLRCalendarQuery_CalendarListList.query()
            query.minAccessRole = "writer"
            self.googleService.executeQuery(query, completionHandler: { (_, response, error) in
                if let error = error {
                    emitter(.error(error))
                }
                guard let response = response as? GTLRCalendar_CalendarList,
                      let entries = response.items else {
                    emitter(.error(GoogleCalendarRepositoryError.InvalidResponseError))
                    return
                }
                let identifiers = entries.map({ (entry) -> String in
                    let data = NSKeyedArchiver.archivedData(withRootObject: entry)
                    let identifier = entry.identifier!
                    self.userDefaults.set(data, forKey: identifier)
                    return identifier
                })
                let accountIdentifier = "\(self.googleUser.userID!).calendars"
                self.userDefaults.set(identifiers, forKey: accountIdentifier)
                emitter(.completed)
            })
            return Disposables.create()
        })
    }
}
