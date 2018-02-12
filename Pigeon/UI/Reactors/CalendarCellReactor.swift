//
//  CalendarCellReactor.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import UIKit
import ReactorKit

public final class CalendarCellReactor: Reactor {
    
    public typealias Action = NoAction

    public let initialState: CalendarCellModel
    
    init(calendar: CalendarCellModel) {
        self.initialState = calendar
    }
}
