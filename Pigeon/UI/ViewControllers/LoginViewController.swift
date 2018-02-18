//
//  LoginViewController.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/10.
//

import GoogleSignIn
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

class LoginViewController: UITableViewController, View {
    typealias Reactor = LoginReactor
    var disposeBag: DisposeBag = DisposeBag()
    let onLoginEventKit = PublishSubject<Void>()
    let onLoginGoogle = PublishSubject<GIDGoogleUser>()

    init(_ reactor: LoginReactor) {
        super.init(style: .grouped)
        self.reactor = reactor
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(reactor: LoginReactor) {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.rx.itemSelected.map {
            if $0.row == 0 {
                return SupportedProvider.EventKit
            } else {
                return SupportedProvider.Google
            }
        }
        .map { Reactor.Action.login($0) }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        onLoginEventKit
            .map { Reactor.Action.loggedInEventKit }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        onLoginGoogle
            .map { Reactor.Action.loggedInGoogle($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.asObservable().map { $0.loggingingService }
            .subscribe(onNext: { provider in
                if let provider = provider {
                    switch provider {
                    case .EventKit:
                        self.loginToEventKit()
                    case .Google:
                        self.loginToGoogle()
                    }
                }
            })
            .disposed(by: disposeBag)

        reactor.state.asObservable().map { $0.loginState }
            .subscribe(onNext: { state in
                if let state = state {
                    switch state {
                    case .success:
                        print("success")
                    case let .failed(error):
                        print("failed \(error)")
                    case .loggingin:
                        break
                    }
                }
            })
            .disposed(by: disposeBag)

        reactor.state.asObservable().map { $0.title }
            .subscribe(onNext: { self.title = $0 })
            .disposed(by: disposeBag)
    }
}

extension LoginViewController {
    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 2
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "\(indexPath.row):\(indexPath.row)")
        if indexPath.row == 0 {
            cell.textLabel?.text = "iOS"
        } else {
            cell.textLabel?.text = "Google"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
