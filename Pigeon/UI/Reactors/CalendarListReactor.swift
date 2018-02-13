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
    }
    
    public enum Mutation {
        case setCalendarSections([CalendarSection])
        case selectedCalendar(IndexPath)
        case setTitle(String)
        case setShowAddCalendarButton(Bool)
    }
    
    public struct State {
        var calendarSections: [CalendarSection]
        var selectedCalendar: CalendarCellReactor?
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
            return provider.calendarService.refreshCalendars().flatMap { _ -> Observable<[(CalendarProviderCellModel ,[CalendarCellModel])]> in
                print("flatmap")
                return self.provider.calendarService.calendars
                }
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
                    print("\(idx) \(section.section.name)")
                    state.calendarSections.remove(at: idx)
                }
                state.calendarSections += [section]
            })
            
            return state
        case let .selectedCalendar(indexPath):
            let cellReactor = state.calendarSections[indexPath.section].items[indexPath.row]
            state.selectedCalendar = cellReactor
            return state
        case let .setTitle(title):
            state.title = title
            return state
        case let .setShowAddCalendarButton(showAddCalendarButton):
            state.showAddCalendarButton = showAddCalendarButton
            return state
        }
    }
}

