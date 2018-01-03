//
//  LoginViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/27.
//

import UIKit
import Hydra

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
                self.userAccountRepository?.store(account: userAccount)
                    .then { Void -> Promise<[Calendar]> in
                        print("store success")
                        return userAccount.fetchModifiableCalendar()
                    }.then({ (calendars) -> Promise<[Void]> in
                        let promises = calendars.map({self.calendarRepository?.store(calendar: $0, fromUserAccount: userAccount)}).filter({$0 != nil}).map({$0!})
                        return all(promises)
                    }).then(in: .main) { _ in
                        print("calendar stored")
                }
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

