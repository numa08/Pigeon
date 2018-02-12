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
        case loggedInFailed
    }
    
    enum Mutation {
        case loginToProvider(SupportedProvider)
        case loggedInFinished(LoginState)
    }

    enum LoginState {
        case success
        case failed
        case loggingin
    }
    
    struct State {
        var loggingingService: SupportedProvider?
        var loginState: LoginState?
    }
    
    public let initialState: LoginReactor.State
    let provider: ServiceProviderType
    
    init(_ serviceProvider: ServiceProviderType) {
        self.provider = serviceProvider
        self.initialState = State(
            loggingingService: nil,
            loginState: nil
        )
    }
    
    func mutate(action: LoginReactor.Action) -> Observable<LoginReactor.Mutation> {
        switch action {
        case let .login(provider):
            return Observable.just(Mutation.loginToProvider(provider))
        case .loggedInEventKit:
            return Observable.just(Mutation.loggedInFinished(.success))
        case .loggedInGoogle(_):
            fatalError("TODO")
        case .loggedInFailed:
            return Observable.just(Mutation.loggedInFinished(.failed))
        }
    }

    func reduce(state: LoginReactor.State, mutation: LoginReactor.Mutation) -> LoginReactor.State {
        var state = state
        switch mutation {
        case let .loginToProvider(provider):
            state.loggingingService = provider
            state.loginState = .loggingin
            
        case let .loggedInFinished(result):
            state.loginState  = result
        }
        return state
    }
    
}
