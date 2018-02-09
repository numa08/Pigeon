//
//  C.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import ReactorKit
import RxSwift
import RxDataSources

public struct CalendarSection {
    let section: String
    public var items: [CalendarCellReactor]
}

extension CalendarSection: SectionModelType {
    
    public typealias Item = CalendarCellReactor
    
    public init(original: CalendarSection, items: [CalendarCellReactor]) {
        self = original
        self.items = items
    }
}


final public class CalendarListReactor: Reactor {
    
    public let initialState: CalendarListReactor.State
    private let provider: ServiceProviderType
    
    public enum Action {
        case loadCalendarSections
        case selectedCalendar(IndexPath)
    }
    
    public enum Mutation {
        case setCalendarSections([CalendarSection])
        case selectedCalendar(IndexPath)
    }
    
    public struct State {
        var calendarSections: [CalendarSection]
        var selectedCalendar: IndexPath?
    }
    
    init(
        _ serviceProvider: ServiceProviderType
        ) {
        self.provider = serviceProvider
        self.initialState = State(
            calendarSections: [],
            selectedCalendar: nil)
    }
    
    public func mutate(action: CalendarListReactor.Action) -> Observable<CalendarListReactor.Mutation> {
        switch action {
        case .loadCalendarSections:
            return self.provider.calendarService
            .fetchCalendars()
                .map({ (_) -> Mutation in
                    return Mutation.setCalendarSections([])
                })
        case let .selectedCalendar(indexPath):
            return Observable.just(Mutation.selectedCalendar(indexPath))
        }
    }
    
    public func reduce(state: CalendarListReactor.State, mutation: CalendarListReactor.Mutation) -> CalendarListReactor.State {
        var state = state
        state.selectedCalendar = nil
        switch mutation {
        case let .setCalendarSections(calendarSections):
            state.calendarSections = calendarSections
            return state
        case let .selectedCalendar(indexPath):
            state.selectedCalendar = indexPath
            return state
        }
    }
}

