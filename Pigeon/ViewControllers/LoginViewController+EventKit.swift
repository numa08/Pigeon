//
//  LoginViewController+EventKit.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import UIKit
import EventKit

enum EventKitCalendarError: Error {
    case AuthorizationStatusRestricted
    case AccessRequestDenied
}

extension LoginViewController {
    
    func requestAccessEventKitCalendar(_ completion: @escaping (UserAccount? ,Error?) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .restricted:
            completion(nil, EventKitCalendarError.AuthorizationStatusRestricted)
            return
        case .authorized:
            completion(EventKitAccount(), nil)
            return
        default:
            break
        }
        let store = EKEventStore()
        store.requestAccess(to: .event) { (granted, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            if !granted {
                completion(nil, EventKitCalendarError.AccessRequestDenied)
                return
            }
            completion(EventKitAccount(),nil)
        }
    }
    
}
