//
//  CalendarBodyBuildViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import UIKit
import Eureka
import GoogleSignIn

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
                $0.optionsProvider = .lazy({(_, completion) in
                    
                    self.calendarRepository.fetchCalendarList(uiDelegate: self, completion: {(list, error) in
                        if let error = error {
                            print("fetch calendar error \(error.localizedDescription)")
                            return
                        }
                        let calendars = list.map({ $0.summary! + "," + $0.identifier! })
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
        }
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
