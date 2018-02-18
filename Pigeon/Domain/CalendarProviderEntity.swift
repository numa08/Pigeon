//
//  CalendarProviderEntity.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation

struct CalendarOwnerIdentifier {
    let value: String
}

extension CalendarOwnerIdentifier: Hashable {
    static func== (lhs: CalendarOwnerIdentifier, rhs: CalendarOwnerIdentifier) -> Bool {
        return lhs.value == rhs.value
    }

    var hashValue: Int {
        return value.hashValue
    }
}

struct CalendarProviderEntity {
    let name: String
    let ownerIdentifier: CalendarOwnerIdentifier?
    let provider: SupportedProvider
}
