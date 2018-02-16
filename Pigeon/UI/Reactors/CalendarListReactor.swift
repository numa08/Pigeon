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
    let section: CalendarProviderCellModel
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
    let provider: ServiceProviderType
    
    public enum Action {
        case loadCalendarSections
        case selectedCalendar(IndexPath)
        case setTitle(String)
        case setShowAddCalendarButton(Bool)
        case refreshCalendars
    }
    
    public enum Mutation {
        case setCalendarSections([CalendarSection])
        case selectedCalendar(IndexPath)
        case setTitle(String)
        case setShowAddCalendarButton(Bool)
        case refreshedCalendars
    }
    
    public struct State {
        var calendarSections: [CalendarSection]
        var selectedCalendar: (CalendarProviderCellModel, CalendarCellReactor)?
        var title: String?
        var showAddCalendarButton: Bool
    }
    
    init(
        _ serviceProvider: ServiceProviderType
        ) {
        self.provider = serviceProvider
        self.initialState = State(
            calendarSections: [],
            selectedCalendar: nil,
            title: nil,
            showAddCalendarButton: false)
    }
    
    public func mutate(action: CalendarListReactor.Action) -> Observable<CalendarListReactor.Mutation> {
        switch action {
        case let .setTitle(title):
            return Observable.just(Mutation.setTitle(title))
        case .loadCalendarSections:
            return
                provider.calendarService.calendars
                    .map({ (cellModels) -> [CalendarSection] in
                    return cellModels.map({ (arg) -> CalendarSection in
                        let (provider, cells) = arg
                        let reactors = cells.map({ CalendarCellReactor(calendar: $0) })
                        return CalendarSection(section: provider, items: reactors)
                    })
                })
                .map({ Mutation.setCalendarSections($0) })
        case let .selectedCalendar(indexPath):
            return Observable.just(Mutation.selectedCalendar(indexPath))
        case let .setShowAddCalendarButton(showAddCalendarButton):
            return Observable.just(Mutation.setShowAddCalendarButton(showAddCalendarButton))
        case .refreshCalendars:
            provider.calendarService.refreshCalendars()
            return Observable.just(Mutation.refreshedCalendars)
        }
    }
    
    public func reduce(state: CalendarListReactor.State, mutation: CalendarListReactor.Mutation) -> CalendarListReactor.State {
        var state = state
        state.selectedCalendar = nil
        switch mutation {
        case let .setCalendarSections(calendarSections):
            calendarSections.forEach({section in
                // 同じセクションの物を削除する
                if let idx = state.calendarSections.index(where: {$0.section == section.section}) {
                    state.calendarSections.remove(at: idx)
                }
                state.calendarSections += [section]
            })
            
            return state
        case let .selectedCalendar(indexPath):
            let section = state.calendarSections[indexPath.section]
            let provider = section.section
            let cell = section.items[indexPath.row]
            state.selectedCalendar = (provider, cell)
            return state
        case let .setTitle(title):
            state.title = title
            return state
        case let .setShowAddCalendarButton(showAddCalendarButton):
            state.showAddCalendarButton = showAddCalendarButton
            return state
        case .refreshedCalendars:
            return state
        }
    }
}

