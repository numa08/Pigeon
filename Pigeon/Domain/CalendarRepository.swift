//
//  CalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import RxSwift
import EventKit

protocol CalendarRepository {
    var calendars: Single<[CalendarEntity]> { get }
    func refresh() -> Completable
}

struct EventKitCalendarRepository: CalendarRepository {
    
    let eventStore: EKEventStore
    
    var calendars: Single<[CalendarEntity]> {
        get {
            return Single.create { (emitter) -> Disposable in
                let calendars = self
                    .eventStore
                    .calendars(for: .event)
                    .filter({ $0.allowsContentModifications })
                    .map({
                        return CalendarEntity(
                            id: CalendarEntityId(value: $0.calendarIdentifier)
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
