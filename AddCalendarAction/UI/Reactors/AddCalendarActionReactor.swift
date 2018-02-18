//
//  AddCalendarActionReactor.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/02/16.
//

import Foundation
import ReactorKit
import RxSwift
import UIKit

public final class AddCalendarActionReactor: Reactor {
    public var initialState: AddCalendarActionReactor.State

    public enum RegisteredState {
        case success
        case failure(e: Error)
    }

    public enum Action {
        case handleAppAction(context: NSExtensionContext)
        case register(event: EventTemplateModel)
    }

    public enum Mutation {
        case update(title: String?, url: URL?, description: String?)
        case register(state: RegisteredState)
    }

    public struct State {
        var eventTemplate: EventTemplateModel
        var registerd: RegisteredState?
    }

    let provider: ServiceProviderType

    init(_ serviceProvider: ServiceProviderType) {
        provider = serviceProvider
        initialState = State(eventTemplate: EventTemplateModel.defaultValue(), registerd: nil)
    }

    public func mutate(action: AddCalendarActionReactor.Action) -> Observable<AddCalendarActionReactor.Mutation> {
        switch action {
        case let .handleAppAction(context):
            return provider.eventTemplateRepository.acquireEventTemplateFrom(context: context)
                .observeOn(OperationQueueScheduler(operationQueue: OperationQueue.main))
                .map { Mutation.update(title: $0.title, url: $0.url, description: $0.description) }
        case let .register(template):
            return provider.calendarService.register(event: template)
                .asObservable()
                .map { _ in Mutation.register(state: .success) }
                .catchError { Observable.just(Mutation.register(state: .failure(e: $0))) }
        }
    }

    public func reduce(state: AddCalendarActionReactor.State, mutation: AddCalendarActionReactor.Mutation) -> AddCalendarActionReactor.State {
        var state = state
        switch mutation {
        case let .update(title, url, description):
            var template = state.eventTemplate
            template.title = title
            template.url = url
            template.memo = description
            state.eventTemplate = template
        case let .register(st):
            state.registerd = st
        }
        return state
    }
}
