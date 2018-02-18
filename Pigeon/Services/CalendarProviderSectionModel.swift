//
//  CalendarProviderSectionModel.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation

public struct CalendarProviderCellModel {
    let name: String
    let provider: SupportedProvider
    let entity: CalendarProviderEntity
}

extension CalendarProviderCellModel: Hashable {
    
    public var hashValue: Int {
        get {
            return name.hashValue
        }
    }
    
    public static func == (lhs: CalendarProviderCellModel, rhs: CalendarProviderCellModel) -> Bool {
        return lhs.name == rhs.name
    }
}
