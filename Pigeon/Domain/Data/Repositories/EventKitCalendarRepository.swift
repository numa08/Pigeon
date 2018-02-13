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
    private var _calendars: BehaviorSubject<[(CalendarProviderEntity, [CalendarEntity])]>!
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.previousAuthorizationState = EKEventStore.authorizationStatus(for: .event)
        self._calendars = BehaviorSubject(value: getCalendars())
        subscribeAuthorizationStateChanged()
    }
    
    var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> {
        return _calendars
    }
    
    func refresh() -> Observable<Void> {
        return Observable.just(()).map { _ in
            self._calendars.onNext(self.getCalendars())
            return ()
        }
    }
    
    func getCalendars() -> [(CalendarProviderEntity, [CalendarEntity])] {
        if EKEventStore.authorizationStatus(for: .event) != .authorized {
            return []
        }
        let calendars = self.eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .map({ c -> CalendarEntity in
                return CalendarEntity(
                    id: CalendarEntityId(value: c.calendarIdentifier),
                    title: c.title,
                    detail: c.source.title,
                    color: UIColor(cgColor: c.cgColor)
                )
            })
        return [(CalendarProviderEntity(name: "iOS") ,calendars)]
    }
    
    private var previousAuthorizationState: EKAuthorizationStatus
    
    private func subscribeAuthorizationStateChanged() {
        if previousAuthorizationState == .authorized {
            return
        }
        let currentState = EKEventStore.authorizationStatus(for: .event)
        if currentState == .authorized {
            let calendars = getCalendars()
            _calendars.onNext(calendars)
            return
        }
        DispatchQueue(label: "").asyncAfter(deadline: .now() + 1.0, execute: { self.subscribeAuthorizationStateChanged() })
    }
    
}

