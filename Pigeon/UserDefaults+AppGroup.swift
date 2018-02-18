//
//  UserDefaults+AppGroup.swift
//  Pigeon
//
//  Created by numa08 on 2018/01/07.
//

import Foundation

extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: "group.com.covelline.pigeon")!
    }
}
