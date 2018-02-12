//
//  CalendarService.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import RxSwift
import UIKit

protocol CalendarServiceType {
    var calendars: Observable<[(CalendarProviderCellModel ,[CalendarCellModel])]> { get }
    func refreshCalendars() -> Observable<Void>
}

struct CalendarService: CalendarServiceType {
    
    let repositories: [CalendarRepositoryType]
    
    var calendars: Observable<[(CalendarProviderCellModel ,[CalendarCellModel])]> {
        get {
            let r = repositories.map{ repo -> Observable<[(CalendarProviderCellModel, [CalendarCellModel])]> in
                return repo.calendars.map({ (entities) -> [(CalendarProviderCellModel, [CalendarCellModel])] in
                    return entities.map({ (provider, calendars) -> (CalendarProviderCellModel, [CalendarCellModel]) in
                        let providerCell = CalendarProviderCellModel(name: provider.name)
                        let calendarCells = calendars.map({ (c) -> CalendarCellModel in
                            return CalendarCellModel(id: c.id, title: c.title, detail: c.detail, color: c.color)
                        })
                        return (providerCell, calendarCells)
                    })
                })
            }
            return Observable.merge(r)
        }
    }
    
    func refreshCalendars() -> Observable<Void> {
        return Observable.merge(
            repositories.map { $0.refresh() }
        )
    }
    
}
