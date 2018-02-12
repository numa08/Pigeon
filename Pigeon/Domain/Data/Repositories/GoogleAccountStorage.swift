//
//  File.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import RxSwift

protocol GoogleAccountStorageType {
    var accounts: [(GIDGoogleUser, GTLRCalendar_Colors)] { get }
    func refresh() -> Observable<Void>
    func store(user: GIDGoogleUser) -> Observable<Void>
}

struct GoogleAccountStorage: GoogleAccountStorageType {
    
    let userDefaults: UserDefaults
    
    var accounts: [(GIDGoogleUser, GTLRCalendar_Colors)] {
        get {
            fatalError("TODO")
        }
    }
    
    func refresh() -> Observable<Void> {
        fatalError("TODO")
    }
    
    func store(user: GIDGoogleUser) -> Observable<Void> {
        fatalError("TODO")
    }
    
}
