//
//  rows.swift
//  Pigeon
//
//  Created by numa08 on 2018/01/03.
//

import UIKit

struct UserAccountRow {
    let userAccount: UserAccount
}

struct CalendarRow {
    let calendar: Calendar
}

extension UserAccountRow: Hashable {
    var hashValue: Int {
        get {
            return userAccount.identifier.hashValue
        }
    }
    
    static func ==(rhs: UserAccountRow, lhs: UserAccountRow) -> Bool {
        return rhs.userAccount.identifier == lhs.userAccount.identifier &&
            rhs.userAccount.provider == lhs.userAccount.provider
    }
}

extension CalendarRow: Hashable {
    var hashValue: Int {
        get {
            return calendar.identifier.hashValue
        }
    }
    
    static func==(rhs: CalendarRow, lhs: CalendarRow) -> Bool {
        return rhs.calendar.identifier == lhs.calendar.identifier &&
            rhs.calendar.provider == lhs.calendar.provider
    }
}

extension Calendar {
    
    func toRow() -> CalendarRow {
        return CalendarRow(calendar: self)
    }
    
}

extension UserAccount {
    
    func toRow() -> UserAccountRow {
        return UserAccountRow(userAccount: self)
    }
    
}

extension UserAccountRow {
    
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

extension CalendarRow {
    
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
