//
//  EventTemplateModel.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/17.
//

import Foundation

public struct DateType {
    let value: Date
}
public struct TimeType {
    let value: Date
}
typealias StartDate = DateType
typealias EndDate = DateType
typealias StartTime = TimeType
typealias EndTime = TimeType

public struct EventTemplateModel {
    var title: String?
    var startDate: StartDate
    var endDate: EndDate
    var allDay: Bool
    var startTime: TimeType?
    var endTime: TimeType?
    var url: URL?
    var calendar: CalendarCellValue?
    var memo: String?
    
    static func defaultValue() -> EventTemplateModel {
        return EventTemplateModel(title: nil, startDate: StartDate(value: Date()), endDate: EndDate(value: Date()), allDay: true, startTime: nil, endTime: nil, url: nil, calendar: nil, memo: nil)
    }
}

