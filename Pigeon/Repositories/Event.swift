//
//  EventRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/01/08.
//

import Foundation
import Hydra
import GoogleAPIClientForREST
import EventKit

struct Event {
    let title: String?
    let description: String?
    let allDay: Bool
    let startDateTime: Date
    let endDateTime: Date
    let url: URL?
}

protocol EventHogeHoge {
    func insert(event: Event) -> Promise<Void>
}

extension EventKitCalendar: EventHogeHoge {
    
    func insert(event: Event) -> Promise<Void> {
        return Promise(in: .background) {(resolve, reject, _) in
            let store = EKEventStore.shared
            let object = event.toEventKitEvent()
            do {
                try store.save(object, span: .thisEvent)
                resolve(())
            } catch {
                reject(error)
            }
        }
    }
    
}

extension GoogleCalendar: EventHogeHoge {
    
    func insert(event: Event) -> Promise<Void> {
        return Promise(in: .background) { (resolve, reject, _) in
            self.insert(event: event, completion: { (event, error) in
                if let error = error {
                    reject(error)
                    return
                }
                if let _ = event {
                    resolve(())
                    return
                }
                fatalError("invalid reponse \(String(describing: event))")
            })
        }
    }
    
    private func insert(event: Event, completion: @escaping (GTLRCalendar_Event?, Error?) -> Void) {
        let account = self.account as! GoogleAccount
        let service = GTLRCalendarService()
        service.authorizer = account.user.authentication.fetcherAuthorizer()
        let object = event.toGoogleCalendarEvent()
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: object, calendarId: calendar.identifier!)
        service.executeQuery(query) { (_, response, error) in
            let event = response as? GTLRCalendar_Event
            completion(event, error)
        }
    }
    
}

private extension Event {
    
    func toGoogleCalendarEvent() -> GTLRCalendar_Event {
        let event = GTLRCalendar_Event()
        event.summary = title
        event.descriptionProperty = description
        event.start = GTLRCalendar_EventDateTime()
        event.end = GTLRCalendar_EventDateTime()
        if allDay {
            event.start?.date = GTLRDateTime(forAllDayWith: startDateTime)
            event.end?.date = GTLRDateTime(forAllDayWith: endDateTime)
        } else {
            event.start?.dateTime = GTLRDateTime(date: startDateTime)
            event.end?.dateTime = GTLRDateTime(date: endDateTime)
        }
        return event
    }
    
    func toEventKitEvent() -> EKEvent {
        return EKEvent()
    }
    
}
