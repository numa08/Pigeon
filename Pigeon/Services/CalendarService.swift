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
    
    var calendars: Observable<[(CalendarProviderCellModel ,[CalendarCellModel])]>
    
    init(repositories: [CalendarRepositoryType] ) {
        self.repositories = repositories
        self.calendars = Observable.merge(
            repositories.map { (repository) -> Observable<[(CalendarProviderCellModel, [CalendarCellModel])]> in
                repository.calendars.map({ (entities) -> [(CalendarProviderCellModel, [CalendarCellModel])] in
                    return entities.map({ (provider, calendars) -> (CalendarProviderCellModel, [CalendarCellModel]) in
                        let providerCell = CalendarProviderCellModel(name: provider.name)
                        let calendarCells = calendars.map({ (c) -> CalendarCellModel in
                            return CalendarCellModel(id: c.id, title: c.title, detail: c.detail, color: c.color)
                        })
                        return (providerCell, calendarCells)
                    })
                })
            })
    }
    
    
    func refreshCalendars() -> Observable<Void> {
        return Observable.merge(
            repositories.map { $0.refresh() }
        )
    }
    
}
