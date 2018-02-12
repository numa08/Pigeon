//
//  CalendarService.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import RxSwift
import UIKit

protocol CalendarServiceType {
    func fetch(calendarForIdentifier identifier: CalendarEntityId, forProvider provider: CalendarProviderCellModel) -> Observable<CalendarCellModel>
    func fetchCalendars() -> Observable<[CalendarProviderCellModel :[CalendarCellModel]]>
    func refreshCalendars() -> Completable
}

struct CalendarService: CalendarServiceType {
    
    var repositories: [CalendarRepository] = []
    
    func fetch(calendarForIdentifier identifier: CalendarEntityId, forProvider provider: CalendarProviderCellModel) -> Observable<CalendarCellModel> {
        fatalError("TODO")
    }
    
    func fetchCalendars() -> Observable<[CalendarProviderCellModel : [CalendarCellModel]]> {
        let r = repositories.map{ repo in
            repo.calendars.asObservable().map { entities -> [CalendarProviderCellModel : [CalendarCellModel]] in
                let cells = entities.map{ e -> CalendarCellModel in
                    CalendarCellModel(id: e.id, title: e.title, detail: e.detail, color: e.color)
                }
                return [
                  CalendarProviderCellModel(name: repo.providerName)
                    : cells
                ]
            }
        }
        return Observable.merge(r)
    }
    
    func refreshCalendars() -> Completable {
        return Completable.merge(
            repositories.map{ $0.refresh() }
        )
    }
}
