//
//  AddCalendarActionReactor.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/02/16.
//

import Foundation
import RxSwift
import ReactorKit

public final class AddCalendarActionReactor: Reactor {

    public var initialState: AddCalendarActionReactor.State
    
    public enum RegisteredState {
        case success
        case failure(e: Error)
    }
    
    public enum Action {
        case updateTitle(title: String?)
        case updateStartDate(date: Date)
        case updateEndDate(date: Date)
        case updateAllDay(allDay: Bool)
        case updateStartTime(date: Date?)
        case updateEndTime(date: Date?)
        case updateURL(url: URL?)
        case updateDescription(description: String)
        case updateCalendar(calendar: CalendarCellModel?)
        case register
    }
    
    public enum Mutation {
        case setTitle(title: String?)
        case setStartDate(date: Date)
        case setEndDate(date: Date)
        case setAllDay(allDay: Bool)
        case setStartTime(date: Date?)
        case setEndTime(date: Date?)
        case setURL(url: URL?)
        case setDescription(description: String)
        case setCalendar(calendar: CalendarCellModel?)
        case register(state: RegisteredState)
    }
    
    public struct State {
        var title: String?
        var startDate: Date
        var endDate: Date
        var allDay: Bool
        var startTime: Date?
        var endTime: Date?
        var url: URL?
        var description: String?
        var calendar: CalendarCellModel?
        var registerd: RegisteredState?
    }
    
    let provider: ServiceProviderType
    
    init (_ serviceProvider: ServiceProviderType) {
        self.provider = serviceProvider
        self.initialState = State(title: nil, startDate: Date(), endDate: Date(), allDay: true, startTime: nil, endTime: nil, url: nil, description: nil, calendar: nil, registerd: nil)
    }
    
    public func mutate(action: AddCalendarActionReactor.Action) -> Observable<AddCalendarActionReactor.Mutation> {
        switch action {
        case let .updateTitle(title):
            return Observable.just(Mutation.setTitle(title: title))
        case let .updateStartDate(date):
            return Observable.just(Mutation.setStartDate(date: date))
        case let .updateEndDate(date):
            return Observable.just(Mutation.setEndDate(date: date))
        case let .updateAllDay(allDay):
            return Observable.just(Mutation.setAllDay(allDay: allDay))
        case let .updateStartTime(startTile):
            return Observable.just(Mutation.setStartTime(date: startTile))
        case let .updateEndTime(endTime):
            return Observable.just(Mutation.setEndTime(date: endTime))
        case let .updateURL(url):
            return Observable.just(Mutation.setURL(url: url))
        case let .updateDescription(description):
            return Observable.just(Mutation.setDescription(description: description))
        case let .updateCalendar(calendar):
            return Observable.just(Mutation.setCalendar(calendar: calendar))
        case .register:
            return Observable.just(Mutation.register(state: .success))
        }
    }
    
    public func reduce(state: AddCalendarActionReactor.State, mutation: AddCalendarActionReactor.Mutation) -> AddCalendarActionReactor.State {
        var state = state
        switch mutation {
        case let .setTitle(title):
            state.title = title
        case let .setStartDate(date):
            state.startDate = date
        case let .setEndDate(date):
            state.endDate = date
        case let .setAllDay(allDay):
            state.allDay = allDay
        case let .setStartTime(date):
            state.startTime = date
        case let .setEndTime(date):
            state.endTime = date
        case let .setURL(url):
            state.url = url
        case let .setDescription(description):
            state.description = description
        case let .setCalendar(calendar):
            state.calendar = calendar
        case let .register(st):
            state.registerd = st
        }
        return state
    }
}
