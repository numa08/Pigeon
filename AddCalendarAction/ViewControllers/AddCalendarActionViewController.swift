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
    var url: URL? = nil
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
                    return async(in: .background, {_ -> CalendarTemplate in
                        guard let urlString = try? await(provider.loadItem(forTypeIdentifier: (kUTTypeURL as String))),
                            let url = urlString as? URL else {
                                fatalError("invalid item provided")
                        }
                        let openGraph = try? await(HttpOpenGraphRepository.shared.openGraph(forURL: url))
                        return CalendarTemplate(title: openGraph?[.title], description: openGraph?[.description], url: url)
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
                if let url = $0.url {
                    calendarTemplate.url = url
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
                $0.placeholder = "タイトル(必須)"
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
            <<< CalendarRow("Calendar") {
                $0.title = "カレンダー(必須)"
                $0.selectorTitle = "カレンダー"
                $0.add(rule: RuleRequired())
            }
            
            +++ Section()
            <<< URLRow("URL") {
                $0.placeholder = "URL"
            }
            <<< TextAreaRow("Description") {
                $0.placeholder = "メモ"
                $0.value = self.calendarTemplate?.description
            }
            +++ Section()
            <<< ButtonRow("Register") {
                    $0.title = "追加"
                }.onCellSelection({(_, _) in
                    let error = !self.form.validate().isEmpty
                    if error { return }
                    guard let titleRow: TextRow = self.form.rowBy(tag: "Title"),
                        let title = titleRow.value,
                        let urlRow: URLRow = self.form.rowBy(tag: "URL"),
                        let url = urlRow.value,
                        let allDayRow: SwitchRow = self.form.rowBy(tag: "AllDay"),
                        let allDay = allDayRow.value,
                        let calendarRow: CalendarRow = self.form.rowBy(tag: "Calendar"),
                        let calendar = calendarRow.value?.calendar else { fatalError("check tag") }
                    let (start, end) = {() -> (Date, Date) in
                        if allDay {
                            guard let startRow: DateRow = self.form.rowBy(tag: "StartDate"),
                                let start = startRow.value,
                                let endRow: DateRow = self.form.rowBy(tag: "EndDate"),
                                let end = endRow.value else { fatalError("check tag") }
                            return (start, end)
                        } else {
                            guard let startRow: DateTimeRow = self.form.rowBy(tag: "StartDateTime"),
                                let start = startRow.value,
                                let endRow: DateTimeRow = self.form.rowBy(tag: "EndDateTime"),
                                let end = endRow.value else { fatalError("check tag") }
                            return (start, end)
                        }
                    }()
                    let descriptionRow: TextAreaRow? = self.form.rowBy(tag: "Description")
                    let description = descriptionRow?.value

                    let event = Event(title: title, description: description, allDay: allDay, startDateTime: start, endDateTime: end, url: url)
                    calendar.insert(event: event).then(in: .main) {(_) in
                        self.extensionContext?.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
                    }
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
        if let url: URLRow = form.rowBy(tag: "URL") {
            url.value = calendarTemplate?.url
        }
        tableView.reloadData()
    }

}

extension CalendarValue: CustomStringConvertible {
    
    public var description: String {
        switch calendar.provider {
        case .EventKit:
            let calendar = self.calendar as! EventKitCalendar
            return "iOS: \(calendar.calendar.title)"
        case .Google:
            let calendar = self.calendar as! GoogleCalendar
            let account = self.calendar.account as! GoogleAccount
            return "\(calendar.calendar.summary!) \(account.user.profile.email!)"
        }
    }
    
}
