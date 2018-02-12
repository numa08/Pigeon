//
//  LoginReactor.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import Foundation
import RxSwift
import ReactorKit
import GoogleSignIn

final class LoginReactor: Reactor {
    enum Action {
        case login(SupportedProvider)
        case loggedInEventKit
        case loggedInGoogle(GIDGoogleUser)
    }
    
    enum Mutation {
        case loginToProvider(SupportedProvider)
        case loggedInFinished(LoginState)
    }

    enum LoginState {
        case success
        case failed(Error)
        case loggingin
    }
    
    struct State {
        var loggingingService: SupportedProvider?
        var loginState: LoginState?
        var title: String?
    }
    
    public let initialState: LoginReactor.State
    let provider: ServiceProviderType
    
    init(_ serviceProvider: ServiceProviderType) {
        self.provider = serviceProvider
        self.initialState = State(
            loggingingService: nil,
            loginState: nil,
            title: "ログイン"
        )
    }
    
    func mutate(action: LoginReactor.Action) -> Observable<LoginReactor.Mutation> {
        switch action {
        case let .login(provider):
            return Observable.just(Mutation.loginToProvider(provider))
        case .loggedInEventKit:
            return Observable.just(Mutation.loggedInFinished(.success))
        case let .loggedInGoogle(user):
            return provider.googleAccountStorage.store(user: user)
            .subscribeOn(OperationQueueScheduler(operationQueue: OperationQueue()))
            .observeOn(OperationQueueScheduler(operationQueue: OperationQueue.main))
            .map({ _ in Mutation.loggedInFinished(.success) })
            .catchError({ Observable.just(Mutation.loggedInFinished(.failed($0))) })
        }
    }

    func reduce(state: LoginReactor.State, mutation: LoginReactor.Mutation) -> LoginReactor.State {
        var state = state
        switch mutation {
        case let .loginToProvider(provider):
            state.loggingingService = provider
            state.loginState = .loggingin
            
        case let .loggedInFinished(result):
            state.loggingingService = nil
            state.loginState  = result
        }
        return state
    }
    
}
