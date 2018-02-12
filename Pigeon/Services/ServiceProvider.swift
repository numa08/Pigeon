//
//  ServiceProvider.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation

protocol ServiceProviderType {
    var calendarService: CalendarServiceType { get }
    var googleAccountStorage: GoogleAccountStorageType { get }
}

struct ServiceProvider: ServiceProviderType {
    let googleAccountStorage: GoogleAccountStorageType
    let calendarService: CalendarServiceType
}
