//
//  CalendarBodyBuildViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import UIKit
import Eureka
import EventKit

class CalendarBodyBuildViewController: FormViewController {

    private var eventStore: EKEventStore? = nil
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
            <<< PushRow<EKCalendar>("Calendar") {
                $0.title = "カレンダー"
                $0.selectorTitle = "カレンダー"
                $0.optionsProvider = .lazy({(_, completion) in
                    self.authorizedEventStore(completion: { (eventStore, error) in
                        guard let ev = eventStore else {
                            fatalError("get eventstore error \(error!)")
                        }
                        let calendars = ev.calendars(for: .event).filter({$0.allowsContentModifications })
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
                if self.form.validate().isEmpty {
                    guard let eventStore = self.eventStore else {
                        fatalError("eventStore is nil")
                    }
                    guard let calendarRow: PushRow<EKCalendar> = form.rowBy(tag: "Calendar"),
                        let calendar = calendarRow.value else {
                            fatalError("Calendar is nil")
                    }
                    
                    guard let titleRow: TextRow = form.rowBy(tag: "Title"),
                        let title = titleRow.value else {
                        fatalError("titleRow is nil")
                    }
                    guard let allDayRow: SwitchRow = form.rowBy(tag: "AllDay"),
                        let allDay = allDayRow.value else {
                            fatalError("allDayRow is nil")
                    }
                    func rowFor(dateRowTag: String, dateTimeRowTag: String) -> RowOf<Date> {
                        if allDay {
                            guard let row: DateRow = form.rowBy(tag: dateRowTag) else {
                                fatalError("\(dateRowTag) is nil")
                            }
                            return row
                        } else {
                            guard let row: DateTimeRow = form.rowBy(tag: dateTimeRowTag) else {
                                fatalError("\(dateTimeRowTag) is nil")
                            }
                            return row
                        }
                    }
                    let startRow = rowFor(dateRowTag: "StartDate", dateTimeRowTag: "StartDateTime")
                    guard let start = startRow.value else {
                        fatalError("startRow is nil")
                    }
                    let endRow = rowFor(dateRowTag: "EndDate", dateTimeRowTag: "EndDateTime")
                    guard let end = endRow.value else {
                        fatalError("endRow is nil")
                    }
                    let _ = self.buildEventItem(title: title, allDay: allDay, startDate: start, endDate: end, calendar: calendar, description: "", eventStore: eventStore)
                }
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
