//
//  ServiceProvider.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import EventKit
import GoogleSignIn
import GoogleAPIClientForREST

protocol ServiceProviderType {
    var calendarService: CalendarServiceType { get }
    var googleAccountStorage: GoogleAccountStorageType { get }
}

struct ServiceProvider: ServiceProviderType {
    let googleAccountStorage: GoogleAccountStorageType
    let calendarService: CalendarServiceType
    
    
    static var serviceProvider: ServiceProviderType = {
        let userDefaults = UserDefaults.shared
        let googleAccountStorage = GoogleAccountStorage(userDefaults: userDefaults)
        let serviceProvider = ServiceProvider(
            googleAccountStorage: googleAccountStorage,
            calendarService: CalendarService(repositories: [
                EventKitCalendarRepository(eventStore: EKEventStore())
                ,GoogleCalendarRepository(accountStorage: googleAccountStorage, googleService: { GTLRCalendarService() }, userDefaults: userDefaults)
                ]))
        return serviceProvider
    }()

}
