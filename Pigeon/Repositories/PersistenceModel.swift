//
//  StorableModel.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import Foundation

protocol PersistenceModel {}

protocol UnStorableModel: PersistenceModel {}

protocol UserDefaultsStorableModel: PersistenceModel {
    func store(toUserDefaults userDefaults: UserDefaults, forKey key: String)
}

extension NSCoding {
    
    func archivedData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
}

protocol NSCodingStorableModel: UserDefaultsStorableModel {
    var persistanceDate: NSCoding { get }
}
extension NSCodingStorableModel {
    
    func store(toUserDefaults userDefaults: UserDefaults, forKey key: String) {
        let data = persistanceDate.archivedData()
        userDefaults.set(data, forKey: key)
    }
    
}
