//
//  rows.swift
//  Pigeon
//
//  Created by numa08 on 2018/01/03.
//

import UIKit

extension UserAccountValue {
    
    func sectionHeaderFor(_ tableView: UITableView) -> String? {
        switch userAccount.provider {
        case .EventKit:
            return "iOS"
        case .Google:
            let googleAccount = userAccount as! GoogleAccount
            return googleAccount.user.profile.email
        }
    }
    
}

extension CalendarValue {
    
    func cellFor(_ tableView: UITableView) -> UITableViewCell {
        let cell = UITableViewCell()
        switch calendar.provider {
        case .EventKit:
            let eventKitCalendar = calendar as! EventKitCalendar
            cell.textLabel?.text = eventKitCalendar.calendar.title
        case .Google:
            let googleCalendar = calendar as! GoogleCalendar
            cell.textLabel?.text = googleCalendar.calendar.summary
        }
        return cell
    }
    
}
