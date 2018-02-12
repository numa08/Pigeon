//
//  CalendarProviderService.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import RxSwift
import EventKit
import GoogleSignIn

protocol CalendarProviderServiceType {
    func login(toProvider provider: SupportedProvider) -> Observable<Void>
}

struct CalendarProviderService: CalendarProviderServiceType {
    
    let eventKitProviderRepository = EventKitProviderRepository(eventStore: EKEventStore())
    let googleCalendarProviderRepository = GoogleCalendarProviderRepository(gidSignin: GIDSignIn.sharedInstance(), userDefaults: UserDefaults.shared)
    
    func login(toProvider provider: SupportedProvider) -> Observable<Void> {
        switch provider {
        case .EventKit:
            return eventKitProviderRepository.login()
        case .Google:
            return googleCalendarProviderRepository.login()
        }
    }
    
}
