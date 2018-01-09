//
//  UITableViewCell+CalendarValue.swift
//  Pigeon
//
//  Created by numa08 on 2018/01/10.
//

import Foundation
import UIKit

protocol CalendarValueCell {
    func show(calendar: CalendarValue)
}

extension UITableViewCell: CalendarValueCell {
    
    func show(calendar calendarValue: CalendarValue) {
        let calendar = calendarValue.calendar
        switch calendar.provider {
        case .EventKit:
            let eventKitCalendar = calendar as! EventKitCalendar
            textLabel?.text = eventKitCalendar.calendar.title
            detailTextLabel?.text = eventKitCalendar.calendar.source.title
            let calendarColor = UIColor(cgColor: eventKitCalendar.calendar.cgColor)
            if let imageView = imageView {
                let image = calendarColor.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
                imageView.image = image
                imageView.layer.cornerRadius = 12.5
                imageView.layer.masksToBounds = true
            }
        case .Google:
            let googleCalendar = calendar as! GoogleCalendar
            let googleAccount = googleCalendar.account as! GoogleAccount
            textLabel?.text = googleCalendar.calendar.summary
            detailTextLabel?.text = googleAccount.user.profile.email
            if let colorId = googleCalendar.calendar.colorId,
                let colors = googleAccount.colors.calendar?.jsonValue(forKey: colorId) as? [String: String],
                let color = colors["background"] {
                let hex = color.replacingOccurrences(of: "#", with: "")
                let calendarColor = UIColor(hex: hex)
                let image = calendarColor.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
                imageView?.image = image
                imageView?.layer.cornerRadius = 12.5
                imageView?.layer.masksToBounds = true
            }
        }
    }
    
}
