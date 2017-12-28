//
//  LoginViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import UIKit

class LoginViewController: UITableViewController {
    
    private var userAccountRepository: UserAccountRepository? = nil
    private var calendarRepository: CalendarRepository? = nil
    
    enum CalendarProviderCell: Int {
        case iOS = 0
        case Google = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userAccountRepository = (UIApplication.shared.delegate as? AppDelegate)?.userAccountRepository
        calendarRepository = (UIApplication.shared.delegate as? AppDelegate)?.calendarRepository
        
        userAccountRepository?.restore({(accounts, error) in
            if let error = error {
                print("restore account error. \(error)")
                return
            }
            accounts.forEach({account in
                self.calendarRepository?.restore(forAccount: account, completion: {(calendar, error) in
                    if let error = error {
                        print("restore calendar error. \(error)")
                        return
                    }
                    calendar.forEach({ print("\($0.provider), \($0.identifier)") })
                })
            })
        })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = CalendarProviderCell(rawValue: indexPath.row) else {
            fatalError("LoginService に定義されていないサービスです。 indexPath: \(indexPath)")
        }
        let completion: (UserAccount? ,Error?) -> Void = {(userAccount, error) in
            if let error = error {
                print("failed login \(error)")
                return
            }
            if let userAccount = userAccount {
                print("login success")
                self.userAccountRepository?.store(account: userAccount, completion: {error in
                    if let error = error {
                        print("failed store \(error)")
                        return
                    }
                    print("store success")
                })
                userAccount.fetchModifiableCalendar({(calendars, error) in
                    if let error = error {
                        print("failed fetch calendar provider: \(userAccount.provider) error \(error)")
                        return
                    }
                    let queueGroup = DispatchGroup()
                    // 非同期に全部を保存するのを待つ
                    calendars.forEach({calendar in
                        DispatchQueue(label: "\(calendar.identifier)").async(group: queueGroup) {
                            var stored = false
                            self.calendarRepository?.store(calendar: calendar, fromUserAccount: userAccount, completion: { _ in stored = true })
                            while(!stored) {}
                        }
                    })
                    queueGroup.notify(queue: DispatchQueue.main) {
                        print("calendar stored")
                    }
                })
            }
        }
        switch cell {
        case .iOS:
            self.requestAccessEventKitCalendar(completion)
        case .Google:
            self.requestAccessGoogleCalendar(completion)
        }
    }
    
}

