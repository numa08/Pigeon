//
//  EventEntity.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/18.
//

import Foundation

struct EventEntity {
    let title: String
    let allDay: Bool
    let start: Date
    let end: Date
    let url: URL?
    let memo: String?
}
