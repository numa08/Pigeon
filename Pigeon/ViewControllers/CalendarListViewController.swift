//
//  CalendarListViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/28.
//

import UIKit

class CalendarListViewController: UITableViewController {
    
    var userAccountRepository: UserAccountRepository? = nil
    var calendarRepository: CalendarRepository? = nil
    
    private var dataSet: [UserAccountRow: [CalendarRow]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userAccountRepository = (UIApplication.shared.delegate as? AppDelegate)?.userAccountRepository
        calendarRepository = (UIApplication.shared.delegate as? AppDelegate)?.calendarRepository
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadRepository()
    }
}

extension CalendarListViewController {
    
    func loadRepository() {
        userAccountRepository?.restore({ (accounts, error) in
            if let error = error {
                print("restore useraccount error \(error)")
                return
            }
            let queueGroup = DispatchGroup()
            // 非同期に全部が読み込まれるのを待つ
            accounts.forEach({account in
                DispatchQueue(label: "\(account.identifier)").async(group: queueGroup) {
                    var restored = false
                    self.calendarRepository?.restore(forAccount: account, completion: {(calendars, error) in
                        if let error = error {
                            print("restore calendar error \(error)")
                            restored = true
                            return
                        }
                        let userAccountRow = account.toRow()
                        let calendarRows = calendars.map({$0.toRow()})
                        self.dataSet[userAccountRow] = calendarRows
                        restored = true
                    })
                    while(!restored) {}
                }
            })
            queueGroup.notify(queue: DispatchQueue.main) {
                self.tableView.reloadData()
            }
        })
    }
    
}

extension CalendarListViewController {
    
    func calendar(forSection section: Int, index: Int) -> CalendarRow {
        let key = Array(dataSet.keys)[section]
        let calendars = dataSet[key]
        return calendars![index]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSet.keys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let account = Array(dataSet.keys)[section]
        return account.sectionHeaderFor(tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = Array(dataSet.keys)[section]
        let calendars = dataSet[key]
        return calendars!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let calendar = self.calendar(forSection: indexPath.section, index: indexPath.row)
        let cell = calendar.cellFor(tableView)
        return cell
    }
}
