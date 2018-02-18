//
//  CalendarCellReactor.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import ReactorKit
import UIKit

public final class CalendarCellReactor: Reactor {
    public typealias Action = NoAction

    public let initialState: CalendarCellModel

    init(calendar: CalendarCellModel) {
        initialState = calendar
    }
}
