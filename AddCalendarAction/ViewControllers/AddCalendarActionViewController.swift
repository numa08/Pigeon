//
//  ActionViewController.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/05.
//

import UIKit
import Eureka
import MobileCoreServices

class AddCalendarActionViewController: FormViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
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
//                $0.value = self.openGraph?[.title]
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
//                $0.optionsProvider = .lazy({(_, completion) in
//
//                    self.calendarRepository.fetchCalendarList(uiDelegate: self, completion: {(list, error) in
//                        if let error = error {
//                            print("fetch calendar error \(error.localizedDescription)")
//                            return
//                        }
//                        let calendars = list.map({ $0.identifier! })
//                        DispatchQueue.main.async {
//                            completion(calendars)
//                        }
//                    })
//                })
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
//                    let calendarID: String = self.form.values["Calendar"]
//                    let event = GTLRCalendar_Event()
//                    event.summary = self.form.valueFor(tag: "Title")
//                    let allDay: Bool = self.form.valueFor(tag: "AllDay")
//                    if allDay {
//                        let start: Date = self.form.valueFor(tag: "StartDate")
//                        let end: Date = self.form.valueFor(tag: "EndDate")
//                        event.start = GTLRCalendar_EventDateTime()
//                        event.start?.dateTime = GTLRDateTime(date: start)
//                        event.end = GTLRCalendar_EventDateTime()
//                        event.end?.dateTime = GTLRDateTime(date: end)
//                        event.originalStartTime = GTLRCalendar_EventDateTime()
//                        event.originalStartTime?.date = GTLRDateTime(date: start)
//                    } else {
//                        let start: Date = self.form.valueFor(tag: "StartDateTime")
//                        let end: Date = self.form.valueFor(tag: "EndDateTime")
//                        event.start = GTLRCalendar_EventDateTime()
//                        event.start?.dateTime = GTLRDateTime(date: start)
//                        event.end = GTLRCalendar_EventDateTime()
//                        event.end?.dateTime = GTLRDateTime(date: end)
//                    }
//                    self.calendarRepository.insertEvent(uiDelegate: self, event: event, calendarID: calendarID, completion: { (_, error) in
//                        if let error = error {
//                            prFormViewControllerint("insert error: \(error)")
//                        } else {
//                            print("insert complete")
//                        }
//                    })
                })
    }
    
    @IBAction func cancel() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
