//
//  CalendarListViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/28.
//

import UIKit
import Hydra

class CalendarListViewController: UITableViewController {
    
    var userAccountRepository: UserAccountRepository? = nil
    var calendarRepository: CalendarRepository? = nil
    
    private var dataSet: [UserAccountValue: [CalendarValue]] = [:]
    
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
        userAccountRepository?.restore().then({ (userAccounts) -> Promise<[(UserAccount, [Calendar])]> in
            let promises = userAccounts.map({ (account) in
                return self.calendarRepository?.restore(forAccount: account).then({ (calendars) in
                    return (account, calendars)
                })
            }).filter({$0 != nil}).map({$0!})
            return all(promises)
        }).then(in: .main) {res in
            res.forEach({ (account, calendars) in
                let accountRow = account.toValue()
                let calendarRows = calendars.map({$0.toValue()})
                self.dataSet[accountRow] = calendarRows
            })
            self.tableView.reloadData()
        }.catch({ (error) in
            print("restore useraccount error \(error)")
        })
    }
    
}

extension CalendarListViewController {
    
    func calendar(forSection section: Int, index: Int) -> CalendarValue {
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
        let cell = calendar.cellFor(tableView, rowAt: indexPath)
        return cell
    }
}
