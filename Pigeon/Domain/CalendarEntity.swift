//
//  CalendarEntity.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import Foundation
import UIKit

public struct CalendarEntityId {
    let value: String
}

extension CalendarEntityId: Hashable {
    
    static public func==(lhs: CalendarEntityId, rhs: CalendarEntityId) -> Bool {
        return lhs.value == rhs.value
    }
    
    public var hashValue: Int {
        return value.hashValue
    }
    
}

public struct CalendarEntity {
    let id: CalendarEntityId
    let title: String
    let detail: String
    let color: UIColor
}
