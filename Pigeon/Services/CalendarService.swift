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
    func refreshCalendars()
}

class CalendarService: CalendarServiceType {
    
    let repositories: [CalendarRepositoryType]
    let disposeBag = DisposeBag()
    let calendarSubjects: PublishSubject<[(CalendarProviderCellModel ,[CalendarCellModel])]> = PublishSubject()
    lazy var calendars: Observable<[(CalendarProviderCellModel ,[CalendarCellModel])]> = {
        return calendarSubjects.share(replay: 1)
    }()
    
    init(repositories: [CalendarRepositoryType] ) {
        self.repositories = repositories
        Observable.from(repositories.map({ $0.calendars }))
            .merge()
            .map({ (entries) -> [(CalendarProviderCellModel, [CalendarCellModel])] in
                return entries.map({(provider, calendars) -> (CalendarProviderCellModel, [CalendarCellModel]) in
                    let providerCell = CalendarProviderCellModel(name: provider.name)
                    let calendarCells = calendars.map({ (c) -> CalendarCellModel in
                        return CalendarCellModel(id: c.id, title: c.title, detail: c.detail, color: c.color)
                    })
                    return (providerCell, calendarCells)
                })
            })
            .subscribe(onNext: { (entries) in
                self.calendarSubjects.onNext(entries)
            })
            .disposed(by: disposeBag)

    }
    
    
    func refreshCalendars() {
        repositories.forEach({ $0.refresh() })
    }
    
}
