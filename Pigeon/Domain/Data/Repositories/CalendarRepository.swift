//
//  CalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import RxSwift

protocol CalendarRepositoryType {
    var calendars: Observable<[(CalendarProviderEntity, [CalendarEntity])]> { get }
    func register(event: EventEntity, inCalendar calendar: CalendarEntity, forProvider provider: CalendarProviderEntity) -> Observable<Void>
    func refresh()
}
