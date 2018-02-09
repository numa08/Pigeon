//
//  CalendarService.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import RxSwift

protocol CalendarServiceType {
    func fetch(calendarForIdentifier identifier: CalendarEntityId) -> Observable<CalendarEntity>
    func fetchCalendars() -> Observable<[[CalendarEntity]]>
    func refreshCalendars() -> Completable
}
