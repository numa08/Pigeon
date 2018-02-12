//
//  LoginViewController+EventKit.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import UIKit
import EventKit

enum EventKitError: Error {
    case AuthorizationStatusRestricted
    case AccessRequestDenied
}

extension LoginViewController {
    
    func loginToEventKit() {
        let state = EKEventStore.authorizationStatus(for: .event)
        switch state {
        case .restricted:
            onLoginEventKit.onError(EventKitError.AuthorizationStatusRestricted)
            return
        case .authorized:
            onLoginEventKit.onNext(())
            return
        default:
            break
        }
        EKEventStore().requestAccess(to: .event) { (granted, error) in
            if let error = error {
                self.onLoginEventKit.onError(error)
                return
            }
            if !granted {
                self.onLoginEventKit.onError(EventKitError.AccessRequestDenied)
                return
            }
            self.onLoginEventKit.onNext(())
        }
    }
    
}
