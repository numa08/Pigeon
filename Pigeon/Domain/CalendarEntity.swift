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

public struct CalendarEntity {
    let id: CalendarEntityId
    let title: String
    let detail: String
    let color: UIColor
}
