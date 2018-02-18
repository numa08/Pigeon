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

class GoogleCalendarRepository: CalendarRepositoryType {
        
    let accountStorage: GoogleAccountStorageType
    let googleService: () -> GTLRCalendarService
    let userDefaults: UserDefaults
    lazy var calendarSubject :PublishSubject<[(CalendarProviderEntity, [CalendarEntity])]> = {
        let subject = PublishSubject<[(CalendarProviderEntity, [CalendarEntity])]>()
        return subject
    }()
    lazy var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> = {
        return calendarSubject.share(replay: 1)
    }()

    let disposeBag = DisposeBag()
    
    init(accountStorage: GoogleAccountStorage,
         googleService: @escaping () -> GTLRCalendarService,
         userDefaults: UserDefaults) {
        self.accountStorage = accountStorage
        self.googleService = googleService
        self.userDefaults = userDefaults
        
        accountStorage.accounts.take(1).subscribe(onNext: {accounts in
            let caches = accounts.map{(user, color) in self.restoreCalendar(forUser: user, withColors: color) }
            self.calendarSubject.onNext(caches)
        }).disposed(by: disposeBag)
        
        accountStorage.accounts.skip(1).flatMap({accounts -> Observable<(GIDGoogleUser ,GTLRCalendar_Colors ,[GTLRCalendar_CalendarListEntry])> in
            return Observable.from(
                accounts.map {(user,colors) in
                    return self.fetchCalendars(forUser: user).map {(user, colors, $0)}
            }).merge()
        })
            .subscribe(onNext: { (user, colors, calendars) in
                self.storeCalendars(calendars, forUser: user)
                let caches = self.restoreCalendar(forUser: user, withColors: colors)
                self.calendarSubject.onNext([caches])
            })
        .disposed(by: disposeBag)
    }
    
    

    enum Errors: Error {
        case InvalidResponseError
        case InvalidObjectStoredError
    }
    enum UserDefaultsKeys: String {
        case CalendarIdentifier = "calenars"
    }
    
    func refresh() {
        accountStorage.refresh()
    }
    
    func storeCalendars(_ entries: [GTLRCalendar_CalendarListEntry], forUser user: GIDGoogleUser) {
        let identifiers = entries.map({ (entry) -> String in
            let data = NSKeyedArchiver.archivedData(withRootObject: entry)
            let identifier = "\(user.userID).calendars.\(entry.identifier!)"
            self.userDefaults.set(data, forKey: identifier)
            return identifier
        })
        let accountIdentifier = "\(user.userID).\(UserDefaultsKeys.CalendarIdentifier.rawValue)"
        self.userDefaults.set(identifiers, forKey: accountIdentifier)
    }
    
    func fetchCalendars(forUser user: GIDGoogleUser) -> Observable<[GTLRCalendar_CalendarListEntry]> {
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
                emitter.onNext(entries)
                emitter.onCompleted()
            })
            return Disposables.create()
        }).share(replay: 1)
    }
    
    func restoreCalendar(forUser user: GIDGoogleUser, withColors colors: GTLRCalendar_Colors) -> (CalendarProviderEntity, [CalendarEntity]) {
        let calendars = restoreCalendar(forUser: user)
        .map({ (entry) -> CalendarEntity in
                let colorId = entry.colorId ?? ""
                let colors = colors.calendar?.jsonValue(forKey: colorId) as? [String: String]
                let color = colors?["background"]
                let hex = color?.replacingOccurrences(of: "#", with: "") ?? ""
                let uiColor = UIColor(hex: hex) ?? UIColor.clear
                return CalendarEntity(id: CalendarEntityId(value: entry.identifier!), title: entry.summary!, detail: "", color: uiColor)
            })
        let provider = CalendarProviderEntity(name: user.profile.email, ownerIdentifier: CalendarOwnerIdentifier(value: user.userID), provider: .Google)
        return (provider, calendars)
    }
    
    func register(event: EventEntity, inCalendar calendar: CalendarEntity, forProvider provider: CalendarProviderEntity) -> Observable<Void> {
        return accountStorage.find(forProvider: provider).map { user -> (GIDGoogleUser, GTLRCalendar_CalendarListEntry) in
            guard let user = user else {
                fatalError()
            }
            guard let googleCalendar = self.restoreCalendar(forUser: user).first(where: { $0.identifier == calendar.id.value }) else {
                fatalError()
            }
            return (user, googleCalendar)
        }.asObservable()
        .flatMap { (arg) -> Observable<Void> in
                let (user, calendar) = arg
            return Observable.create({emitter in
                    let service = self.googleService()
                    service.authorizer = user.authentication.fetcherAuthorizer()
                    let object = event.event()
                    let query = GTLRCalendarQuery_EventsInsert.query(withObject: object, calendarId: calendar.identifier!)
                    service.executeQuery(query, completionHandler: {(_, response, error) in
                        if let error = error {
                            emitter.onError(error)
                        }
                        emitter.onNext(())
                        emitter.onCompleted()
                    })
                    return Disposables.create()
                })
        }
    }
    
    private func restoreCalendar(forUser user: GIDGoogleUser) -> [GTLRCalendar_CalendarListEntry] {
        let identifiers = userDefaults.stringArray(forKey: "\(user.userID).\(UserDefaultsKeys.CalendarIdentifier.rawValue)") ?? []
        let calendars = try! identifiers.map({ (identifier) -> GTLRCalendar_CalendarListEntry in
            guard let data = self.userDefaults.data(forKey: identifier),
                let entry = NSKeyedUnarchiver.unarchiveObject(with: data) as? GTLRCalendar_CalendarListEntry else {
                    throw Errors.InvalidObjectStoredError
            }
            return entry
        })
        return calendars
    }
}

extension EventEntity {
    
    func event() -> GTLRCalendar_Event {
        let event = GTLRCalendar_Event()
        event.summary = title
        event.descriptionProperty = "\(url?.absoluteString ?? "")\n\(memo ?? "")"
        event.start = GTLRCalendar_EventDateTime()
        event.end = GTLRCalendar_EventDateTime()
        if allDay {
            event.start?.date = GTLRDateTime(forAllDayWith: start)
            event.end?.date = GTLRDateTime(forAllDayWith: end)
        } else {
            event.start?.dateTime = GTLRDateTime(date: start)
            event.end?.dateTime = GTLRDateTime(date: end)
        }
        return event
    }
    
}
