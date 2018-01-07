//
//  ActionViewController.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/05.
//

import UIKit
import Eureka
import Hydra
import MobileCoreServices

struct CalendarTemplate {
    var title: String? = nil
    var description: String? = nil
}

class AddCalendarActionViewController: FormViewController {

    let calendarRepository: CalendarRepository = UserDefaultsCalendarRepository(userDefaults: UserDefaults.shared)
    let userAccountRepository: UserAccountRepository = UserDefaultsUserAccountRepository(userDefaults: UserDefaults.shared)
    
    var calendarTemplate: CalendarTemplate? = nil {
        didSet {
            updateRowContent()
        }
    }
    
    override func loadView() {
        super.loadView()
        
        let promises = extensionContext?.inputItems.flatMap({ (item) -> [Promise<CalendarTemplate>] in
            guard let item = item as? NSExtensionItem else {
                return []
            }
            return item.attachments?.map({ (provider) -> Promise<CalendarTemplate> in
                guard let provider = provider as? NSItemProvider else {
                    return Promise.init(resolved: CalendarTemplate())
                }
                if provider.hasItemConformingToTypeIdentifier((kUTTypeURL as String)) {
                    return provider.loadItem(forTypeIdentifier: (kUTTypeURL as String)).then({ (url) -> (Promise<OpenGraph>)in
                        guard let url = url as? URL else {
                            fatalError("invalid item")
                        }
                        return HttpOpenGraphRepository.shared.openGraph(forURL: url)
                    }).then({ (openGraph) -> CalendarTemplate in
                        let description = "\(openGraph[.url] ?? "")\n\(openGraph[.description] ?? "")"
                        return CalendarTemplate(title: openGraph[.title], description: description)
                    })
                }
                fatalError("provider doesn't have expected type item")
            }) ?? []
        }) ?? []
        
        all(promises).then(in: .main) { (templates) in
            var calendarTemplate = CalendarTemplate()
            templates.forEach({
                if let title = $0.title {
                    calendarTemplate.title = title
                }
                if let description = $0.description {
                    calendarTemplate.description = description
                }
            })
            self.calendarTemplate = calendarTemplate
        }
    }

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
                $0.value = self.calendarTemplate?.title
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
                    async(in: .background, {_ -> [Calendar] in
                        let accounts = try await(self.userAccountRepository.restore())
                        return try accounts.flatMap({account in
                            return try await(self.calendarRepository.restore(forAccount: account))
                        })
                    }).then(in: .main, { (calendars: [Calendar]) in
                        let array = calendars.map({ $0.toString() })
                        completion(array)
                    })
                })
            }
            
            +++ Section()
            <<< TextAreaRow("Description") {
                $0.value = self.calendarTemplate?.description
            }
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
    
    private func updateRowContent() {
        if let title: TextRow = form.rowBy(tag: "Title") {
            title.value = calendarTemplate?.title
        }
        if let description: TextAreaRow = form.rowBy(tag: "Description") {
            description.value = calendarTemplate?.description
        }
        tableView.reloadData()
    }

}
