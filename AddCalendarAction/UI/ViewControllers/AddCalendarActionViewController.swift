//
//  ActionViewController.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/05.
//

import Eureka
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

open class AddCalendarActionViewController: FormViewController, View {
    public typealias Reactor = AddCalendarActionReactor
    public var disposeBag: DisposeBag = DisposeBag()
    var navigationManager: NavigationManagerType = NavigationManager()

    open override func viewDidLoad() {
        super.viewDidLoad()
        reactor = AddCalendarActionReactor(ServiceProvider.serviceProvider)
    }

    var currentEventTemplate: EventTemplateModel {
        let title: TextRow? = form.rowBy(tag: "Title")
        let allDay: SwitchRow? = form.rowBy(tag: "AllDay")
        let startDate: DateRow? = form.rowBy(tag: "StartDate")
        let endDate: DateRow? = form.rowBy(tag: "EndDate")
        let startDateTime: DateTimeRow? = form.rowBy(tag: "StartDateTime")
        let endDateTime: DateTimeRow? = form.rowBy(tag: "EndDateTime")
        let calendar: CalendarRow? = form.rowBy(tag: "Calendar")
        let url: URLRow? = form.rowBy(tag: "URL")
        let memo: TextAreaRow? = form.rowBy(tag: "Memo")
        return EventTemplateModel(
            title: title?.value,
            startDate: StartDate(value: startDate?.value ?? Date()),
            endDate: EndDate(value: endDate?.value ?? Date()),
            allDay: allDay!.value!,
            startTime: StartTime(value: startDateTime?.value ?? Date()),
            endTime: EndTime(value: endDateTime?.value ?? Date()),
            url: url?.value,
            calendar: calendar?.value,
            memo: memo?.value)
    }

    public func bind(reactor: AddCalendarActionReactor) {
        if let context = extensionContext {
            Observable.just(Reactor.Action.handleAppAction(context: context))
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }

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
            }
            +++ Section()
            <<< SwitchRow("AllDay") { row in
                row.title = "終日"
                row.add(rule: RuleRequired())
            }
            <<< DateTimeRow("StartDateTime") { row in
                row.title = "開始"
                row.hidden = dateTimeRowPredicate
                row.value = Date()
            }.onChange({ row in
                if let endTimeRow: DateTimeRow = self.form.rowBy(tag: "EndDateTime"),
                    let value = row.value {
                    let newDate = Calendar.current
                    let newVaue = newDate.date(byAdding: DateComponents(hour: 2), to: value)
                    endTimeRow.value = newVaue
                    endTimeRow.updateCell()
                }
            })
            <<< DateTimeRow("EndDateTime") { row in
                row.title = "終了"
                row.hidden = dateTimeRowPredicate
                row.value = {
                    let now = Date()
                    let newDate = Calendar.current
                    return newDate.date(byAdding: DateComponents(hour: 2), to: now)
                }()
            }
            <<< DateRow("StartDate") { row in
                row.title = "開始"
                row.hidden = dateRowPredicate
                row.value = Date()
            }
            <<< DateRow("EndDate") { row in
                row.title = "終了"
                row.hidden = dateRowPredicate
                row.value = Date()
            }
            +++ Section()
            <<< CalendarRow("Calendar") {
                $0.title = "カレンダー(必須)"
                $0.selectorTitle = "カレンダー"
                $0.add(rule: RuleRequired())
            }

            +++ Section()
            <<< URLRow("URL") {
                $0.placeholder = "URL"
            }
            <<< TextAreaRow("Memo") { row in
                row.placeholder = "メモ"
            }
            +++ Section()
            <<< ButtonRow("Register") { row in
                row.title = "登録"
            }.onCellSelection { _, _ in
                if let reactor = self.reactor {
                    let updateTemplateAction = Reactor.Action.updateEventTemplate(event: self.currentEventTemplate)
                    observeAction(action: updateTemplateAction).dispose()
                    let registerEventAction = Reactor.Action.register(event: reactor.currentState.eventTemplate)
                    observeAction(action: registerEventAction).dispose()
                }
            }

        func updateTemplate(_ template: EventTemplateModel) {
            if let title: TextRow = self.form.rowBy(tag: "Title") {
                title.value = template.title
            }
            if let url: URLRow = self.form.rowBy(tag: "URL") {
                url.value = template.url
            }
            if let memo: TextAreaRow = self.form.rowBy(tag: "Memo") {
                memo.value = template.memo
            }
            if let allDay: SwitchRow = self.form.rowBy(tag: "AllDay") {
                allDay.value = template.allDay
            }
            if let startDate: DateRow = self.form.rowBy(tag: "StartDate") {
                startDate.value = template.startDate.value
            }
            if let endDate: DateRow = self.form.rowBy(tag: "EndDate") {
                endDate.value = template.endDate.value
            }
            if let starTime: DateTimeRow = self.form.rowBy(tag: "StartDateTime") {
                starTime.value = template.startTime?.value
            }
            if let endTime: DateTimeRow = self.form.rowBy(tag: "EndDateTime") {
                endTime.value = template.endTime?.value
            }
        }

        reactor.state.asObservable().map { $0.eventTemplate }
            .subscribe(onNext: { template in
                updateTemplate(template)
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    @IBAction func onClickCancel(_: Any) {
        navigationManager.navigationToAddCalendarCancell(current: self)
    }
}
