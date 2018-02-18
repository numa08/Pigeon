//
//  CalendarService.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import RxSwift
import UIKit

protocol CalendarServiceType {
    var calendars: Observable<[(CalendarProviderCellModel, [CalendarCellModel])]> { get }
    func refreshCalendars()
    func register(event template: EventTemplateModel) -> Observable<Void>
}

class CalendarService: CalendarServiceType {
    let googleCalendarRepository: GoogleCalendarRepository
    let eventKitCalendarRepository: EventKitCalendarRepository
    let disposeBag = DisposeBag()
    let calendarSubjects: PublishSubject<[(CalendarProviderCellModel, [CalendarCellModel])]> = PublishSubject()
    lazy var repositories: [CalendarRepositoryType] = {
        [eventKitCalendarRepository, googleCalendarRepository]
    }()

    lazy var calendars: Observable<[(CalendarProviderCellModel, [CalendarCellModel])]> = {
        calendarSubjects.share(replay: 1)
    }()

    init(
        eventKitCalendarRepository: EventKitCalendarRepository,
        googleCalendarRepository: GoogleCalendarRepository
    ) {
        self.eventKitCalendarRepository = eventKitCalendarRepository
        self.googleCalendarRepository = googleCalendarRepository
        Observable.from(repositories.map({ $0.calendars }))
            .merge()
            .map({ (entries) -> [(CalendarProviderCellModel, [CalendarCellModel])] in
                entries.map({ (provider, calendars) -> (CalendarProviderCellModel, [CalendarCellModel]) in
                    let providerCell = CalendarProviderCellModel(name: provider.name, provider: provider.provider, entity: provider)
                    let calendarCells = calendars.map({ (c) -> CalendarCellModel in
                        CalendarCellModel(id: c.id, title: c.title, detail: c.detail, color: c.color, entity: c)
                    })
                    return (providerCell, calendarCells)
                })
            })
            .subscribe(onNext: { entries in
                self.calendarSubjects.onNext(entries)
            })
            .disposed(by: disposeBag)
    }

    func refreshCalendars() {
        repositories.forEach({ $0.refresh() })
    }

    func register(event template: EventTemplateModel) -> Observable<Void> {
        guard let calendar = template.calendar else {
            return Observable.error(EventTemplateModel.Errors.NoCalendarError)
        }
        let provider = calendar.provider
        let repository = { () -> CalendarRepositoryType in
            switch provider.provider {
            case .EventKit:
                return self.eventKitCalendarRepository
            case .Google:
                return self.googleCalendarRepository
            }
        }()
        do {
            let event = try template.toEvent()
            return repository.register(event: event, inCalendar: calendar.calendar.entity, forProvider: provider.entity)
        } catch {
            return Observable.error(error)
        }
    }
}

extension EventTemplateModel {
    enum Errors: Error {
        case NoTitleError
        case NoTimeError
        case NoCalendarError
    }

    func toEvent() throws -> EventEntity {
        guard let title = title else {
            throw Errors.NoTitleError
        }
        if allDay {
            return EventEntity(title: title, allDay: allDay, start: startDate.value, end: endDate.value, url: url, memo: memo)
        }
        guard let startTime = startTime,
            let endTime = endTime else {
            throw Errors.NoTimeError
        }
        let start = date(fromDate: startDate, withTime: startTime)
        let end = date(fromDate: endDate, withTime: endTime)
        return EventEntity(title: title, allDay: allDay, start: start, end: end, url: url, memo: memo)
    }

    func date(fromDate date: DateType, withTime time: TimeType) -> Date {
        let newCalendar = Calendar.current
        return newCalendar.date(from:
            DateComponents(
                year: newCalendar.component(.year, from: date.value),
                month: newCalendar.component(.month, from: date.value),
                day: newCalendar.component(.day, from: date.value),
                hour: newCalendar.component(.hour, from: time.value),
                minute: newCalendar.component(.minute, from: time.value),
                second: newCalendar.component(.second, from: time.value)))!
    }
}
