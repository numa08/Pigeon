//
//  ActionViewController.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/05.
//

import UIKit
import Eureka
import ReactorKit
import RxCocoa
import RxSwift

open class AddCalendarActionViewController: FormViewController, View {
    
    public typealias Reactor = AddCalendarActionReactor
    public var disposeBag: DisposeBag = DisposeBag()
    var navigationManager: NavigationManagerType = NavigationManager()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = AddCalendarActionReactor(ServiceProvider.serviceProvider)
    }
    
    public func bind(reactor: AddCalendarActionReactor) {
        reactor.state.asObservable().map { $0.registerd }
            .filter { $0 != nil }.map { $0! }
            .observeOn(OperationQueueScheduler(operationQueue: OperationQueue.main))
            .subscribe(onNext: { state in
                switch state {
                case .success:
                    self.navigationManager.navigationToOnCompleteEventRegister(current: self)
                case let .failure(e):
                    print(e)
                }
            })
            .disposed(by: disposeBag)
        
        let dateTimeRowPredicate = Condition.function(["AllDay"]) { form in
            guard let switchRow: SwitchRow = form.rowBy(tag: "AllDay") else {
                fatalError("invalid tag")
            }
            return switchRow.value ?? false
        }
        let dateRowPredicate = Condition.function(["AllDay"], { form in
            guard let switchRow: SwitchRow = form.rowBy(tag: "AllDay") else {
                fatalError("invalid tag")
            }
            return !(switchRow.value ?? false)
        })
        
        func observeAction(action: Reactor.Action) -> Disposable {
            return Observable.just(action).bind(to: reactor.action)
        }
        
        form +++ Section()
            <<< TextRow("Title") { row in
                row.placeholder = "タイトル(必須)"
                row.add(rule: RuleRequired())
                reactor.state.asObservable().map { $0.title }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                }.onChange {row in
                    let action = Reactor.Action.updateTitle(title: row.value)
                    observeAction(action: action)
                    .disposed(by: self.disposeBag)
            }
            +++ Section()
            <<< SwitchRow("AllDay") { row in
                row.title = "終日"
                row.add(rule: RuleRequired())
                reactor.state.asObservable().map { $0.allDay }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                }.onChange { row in
                    let action = Reactor.Action.updateAllDay(allDay: row.value!)
                    observeAction(action: action).disposed(by: self.disposeBag)            }
            <<< DateTimeRow("StartDateTime") { row in
                row.title = "開始"
                row.hidden = dateTimeRowPredicate
                }.onChange { row in
                    let action = Reactor.Action.updateStartTime(date: row.value)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            <<< DateTimeRow("EndDateTime") { row in
                row.title = "終了"
                reactor.state.asObservable().map { $0.endDate }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                row.hidden = dateTimeRowPredicate
                }.onChange {row in
                    let action = Reactor.Action.updateEndTime(date: row.value)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            <<< DateRow("StartDate") { row in
                row.title = "開始"
                reactor.state.asObservable().map { $0.startDate }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                row.hidden = dateRowPredicate
                }.onChange { row in
                    let action = Reactor.Action.updateStartDate(date: row.value!)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            <<< DateRow("EndDate") { row in
                row.title = "終了"
                reactor.state.asObservable().map { $0.endDate }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                row.hidden = dateRowPredicate
                }.onChange { row in
                    let action = Reactor.Action.updateEndDate(date: row.value!)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            +++ Section()
//            <<< CalendarRow("Calendar") {
//                $0.title = "カレンダー(必須)"
//                $0.selectorTitle = "カレンダー"
//                $0.add(rule: RuleRequired())
//            }
            
            +++ Section()
            <<< URLRow("URL") {
                $0.placeholder = "URL"
                }.onChange { row in
                    let action = Reactor.Action.updateURL(url: row.value)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            <<< TextAreaRow("Description") { row in
                row.placeholder = "メモ"
                reactor.state.asObservable().map { $0.description }.subscribe(onNext: { row.value = $0 }).disposed(by: self.disposeBag)
                }.onChange {row in
                    let action = Reactor.Action.updateDescription(description: row.value!)
                    observeAction(action: action).disposed(by: self.disposeBag)
            }
            +++ Section()
            <<< ButtonRow("Register") { row in
                row.title = "登録"
                }.onCellSelection { (_, _) in
                    let action = Reactor.Action.register
                    observeAction(action: action).disposed(by: self.disposeBag)
        }
    }

    @IBAction func onClickCancel(_ sender: Any) {
        navigationManager.navigationToAddCalendarCancell(current: self)
    }
}

