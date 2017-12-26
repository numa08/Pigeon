//
//  UIVIewController+EventKit.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import EventKit
import UIKit

extension UIViewController {
    
    func authorizedEventStore(completion: @escaping ((EKEventStore?, Error?) -> Void)) {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            completion(eventStore, nil)
        case .restricted:
            completion(nil, EventStoreError.retrictedError)
        case .denied:
            completion(nil, EventStoreError.deniedError)
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if !granted {
                    completion(nil, error)
                } else {
                    completion(eventStore, error)
                }
            })
        }
    }
    
    func buildEventItem(
        title: String,
        allDay: Bool,
        startDate: Date,
        endDate: Date,
        calendar: EKCalendar,
        description: String,
        eventStore: EKEventStore
        ) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.isAllDay = allDay
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar
        return event
    }
}

enum EventStoreError: Error {
    case retrictedError
    case deniedError
}
