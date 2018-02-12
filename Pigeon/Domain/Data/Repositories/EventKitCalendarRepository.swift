//
//  EventKitRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import EventKit
import RxSwift
import UIKit

struct EventKitCalendarRepository: CalendarRepositoryType {
    
    let eventStore: EKEventStore
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.previousAuthorizationState = EKEventStore.authorizationStatus(for: .event)
        subscribeAuthorizationStateChanged()
    }
    
    var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> {
        get {
            return Observable.create({emitter -> Disposable in
                func observeCalendar()  {
                    let calendars = self.eventStore.calendars(for: .event)
                        .filter { $0.isImmutable }
                        .map({ c -> CalendarEntity in
                            return CalendarEntity(
                                id: CalendarEntityId(value: c.calendarIdentifier),
                                title: c.title,
                                detail: c.source.title,
                                color: UIColor(cgColor: c.cgColor)
                            )
                        })
                    emitter.onNext([(CalendarProviderEntity(name: "iOS") ,calendars)])
                }
//                NotificationCenter.default.addObserver(forName: Notification.Name.EventStoreAuthorized, object: nil, queue: nil, using: {_ in
//                    observeCalendar()
//                })
                observeCalendar()
                return Disposables.create()
            })
        }
    }
    
    func refresh() -> Observable<Void> {
        return Observable.just(())
    }
    
    private var previousAuthorizationState: EKAuthorizationStatus
    
    private func subscribeAuthorizationStateChanged() {
        if previousAuthorizationState == .authorized {
            return
        }
        let currentState = EKEventStore.authorizationStatus(for: .event)
        if currentState == .authorized {
            let notification = Notification.Name.EventStoreAuthorized
            NotificationCenter.default.post(name: notification, object: nil)
            return
        }
        DispatchQueue(label: "").asyncAfter(deadline: .now() + 1.0, execute: { self.subscribeAuthorizationStateChanged() })
    }
    
}

private extension Notification.Name {
    static let EventStoreAuthorized = Notification.Name("EventStoreAuthorized")
}

