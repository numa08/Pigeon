//
//  CalendarBodyBuildViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import UIKit
import Eureka
import GoogleSignIn
import GoogleAPIClientForREST

class CalendarBodyBuildViewController: FormViewController {

    private let calendarRepository: GoogleCalendarRepository = DefaultGoogleCalendarRepository.shared
    public var openGraph: OpenGraph? = nil {
        didSet {
            didUpdateOpenGraph()
        }
    }
}

extension CalendarBodyBuildViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DateTimeRow.defaultRowInitializer = { row in row.minimumDate = Date() }

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
        form +++ Section()
            <<< TextRow("Title") {
                $0.value = self.openGraph?[.title]
                $0.add(rule: RuleRequired())
        }
            +++ Section()
            <<< SwitchRow("AllDay") {
                $0.title = "終日"
                $0.value = false
                $0.add(rule: RuleRequired())
        }
            <<< DateTimeRow("StartDateTime") {
                $0.title = "開始"
                $0.value = Date()
                $0.hidden = dateTimeRowPredicate
        }
            <<< DateTimeRow("EndDateTime") {
                $0.title = "終了"
                $0.value = Date()
                $0.hidden = dateTimeRowPredicate
        }
            <<< DateRow("StartDate") {
                $0.title = "開始"
                $0.value = Date()
                $0.hidden = dateRowPredicate
        }
            <<< DateRow("EndDate") {
                $0.title = "終了"
                $0.value = Date()
                $0.hidden = dateRowPredicate
        }
            +++ Section()
            <<< PushRow<String>("Calendar") {
                $0.title = "カレンダー"
                $0.selectorTitle = "カレンダー"
                $0.add(rule: RuleRequired())
                $0.optionsProvider = .lazy({(_, completion) in
                    
                    self.calendarRepository.fetchCalendarList(uiDelegate: self, completion: {(list, error) in
                        if let error = error {
                            print("fetch calendar error \(error.localizedDescription)")
                            return
                        }
                        let calendars = list.map({ $0.identifier! })
                        DispatchQueue.main.async {
                            completion(calendars)
                        }
                    })
                })
                }
                
            +++ Section()
            <<< TextAreaRow("Description")
            +++ Section()
            <<< ButtonRow("Register") {
                $0.title = "追加"
        }.onCellSelection({(_, _) in
            let error = self.form.validate()
            if !error.isEmpty {
                error.forEach({ print($0.msg) })
                return
            }
            let calendarID: String = self.form.valueFor(tag: "Calendar")
            let event = GTLRCalendar_Event()
            event.summary = self.form.valueFor(tag: "Title")
            let allDay: Bool = self.form.valueFor(tag: "AllDay")
            if allDay {
                let start: Date = self.form.valueFor(tag: "StartDate")
                let end: Date = self.form.valueFor(tag: "EndDate")
                event.start = GTLRCalendar_EventDateTime()
                event.start?.dateTime = GTLRDateTime(date: start)
                event.end = GTLRCalendar_EventDateTime()
                event.end?.dateTime = GTLRDateTime(date: end)
                event.originalStartTime = GTLRCalendar_EventDateTime()
                event.originalStartTime?.date = GTLRDateTime(date: start)
            } else {
                let start: Date = self.form.valueFor(tag: "StartDateTime")
                let end: Date = self.form.valueFor(tag: "EndDateTime")
                event.start = GTLRCalendar_EventDateTime()
                event.start?.dateTime = GTLRDateTime(date: start)
                event.end = GTLRCalendar_EventDateTime()
                event.end?.dateTime = GTLRDateTime(date: end)
            }
            self.calendarRepository.insertEvent(uiDelegate: self, event: event, calendarID: calendarID, completion: { (_, error) in
                if let error = error {
                    print("insert error: \(error)")
                } else {
                    print("insert complete")
                }
            })
        })
    }
    
    private func didUpdateOpenGraph() {
        let titleRow: TextRow? = form.rowBy(tag: "Title")
        titleRow?.value = openGraph?[.title]
        let descriptionRow: TextAreaRow? = form.rowBy(tag: "Description")
        descriptionRow?.value = openGraph?[.description]
        self.tableView.reloadData()
    }
    
}

extension CalendarBodyBuildViewController: GIDSignInUIDelegate {}

private extension Form {
    
    func valueFor<T>(tag: String) -> T where T: Equatable {
        guard let row: RowOf<T> = self.rowBy(tag: tag) else {
            fatalError("Form doesn't have \(tag)")
        }
        guard let value:T = row.value else {
            fatalError("Row for \(tag) doesn't have value")
        }
        return value
    }
    
}
