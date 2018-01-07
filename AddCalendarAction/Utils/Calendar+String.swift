//
//  Calendar+String.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/07.
//

import Foundation

extension Calendar {
    func toString() -> String {
        let str = { () -> String in
            switch self.provider {
            case .EventKit:
                return (self as! EventKitCalendar).calendar.title
            case .Google:
                return (self as! GoogleCalendar).calendar.summary!
            }
        }()
        return str
    }
}


