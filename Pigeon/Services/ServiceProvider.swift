//
//  ServiceProvider.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation

protocol ServiceProviderType {
    var calendarProviderService: CalendarProviderServiceType { get }
    var googleAccountStorage: GoogleAccountStorageType { get }
}

struct ServiceProvider: ServiceProviderType {
    let calendarProviderService: CalendarProviderServiceType
    let googleAccountStorage: GoogleAccountStorageType
}
