//
//  ProviderRepository.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import EventKit
import RxSwift

protocol ProviderRepository {
    var calendarRepository: [CalendarRepository] { get }
    func login() -> Observable<Void>
    func refresh() -> Completable
    
}

enum EventKitProviderRepositoryError: Error {
    case AuthorizationStatusRestricted
    case AccessRequestDenied
}

struct EventKitProviderRepository: ProviderRepository {
    
    let eventStore: EKEventStore
    
    var calendarRepository: [CalendarRepository] {
        get {
            return [EventKitCalendarRepository(eventStore: eventStore)]
        }
    }

    func login() -> Observable<Void> {
        return Observable.create{ emitter in
            let state = EKEventStore.authorizationStatus(for: .event)
            switch state {
            case .restricted:
                emitter.onError(EventKitProviderRepositoryError.AuthorizationStatusRestricted)
                return Disposables.create {}
            case .authorized:
                emitter.onNext(())
                return Disposables.create {}
            default:
                break
            }
            self.eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if let error = error {
                    emitter.onError(error)
                    return
                }
                if !granted {
                    emitter.onError(EventKitProviderRepositoryError.AccessRequestDenied)
                    return
                }
                emitter.onNext(())
            })
            return Disposables.create {}
        }
    }

    func refresh() -> Completable {
        return Completable.create(subscribe: {
            $0(.completed)
            return Disposables.create()
        })
    }
}

