//
//  CalendarCellReactor.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import ReactorKit

public struct CalendarCellModel {
    let id: CalendarEntityId
    var title: String
    var detail: String
    var color: UIColor
}

public final class CalendarCellReactor: Reactor {
    
    public typealias Action = NoAction

    public let initialState: CalendarCellModel
    
    init(calendar: CalendarCellModel) {
        self.initialState = calendar
    }
}
