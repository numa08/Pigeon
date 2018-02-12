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
    func refresh() -> Observable<Void>
}
