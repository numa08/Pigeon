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

class EventKitCalendarRepository: CalendarRepositoryType {

    let eventStore: EKEventStore
    lazy var calendarSubject : BehaviorSubject<[(CalendarProviderEntity, [CalendarEntity])]> = {
        let subject = BehaviorSubject(value: getCalendars())
        return subject
    }()
    lazy var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> = {
        return calendarSubject.share(replay: 1)
    }()

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.previousAuthorizationState = EKEventStore.authorizationStatus(for: .event)
        subscribeAuthorizationStateChanged()
    }
    
    
    func refresh() {
        calendarSubject.onNext(getCalendars())
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
            calendarSubject.onNext(calendars)
            return
        }
        DispatchQueue(label: "").asyncAfter(deadline: .now() + 1.0, execute: { self.subscribeAuthorizationStateChanged() })
    }
    
}

