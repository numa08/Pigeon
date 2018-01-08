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
    
    func cellFor(_ tableView: UITableView, rowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = {() -> UITableViewCell in
            let identifier = "\(indexPath.row)/\(indexPath.section)"
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) {
                return cell
            }
            return UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }()
        
        switch calendar.provider {
        case .EventKit:
            let eventKitCalendar = calendar as! EventKitCalendar
            cell.textLabel?.text = eventKitCalendar.calendar.title
            cell.detailTextLabel?.text = eventKitCalendar.calendar.source.title
            let calendarColor = UIColor(cgColor: eventKitCalendar.calendar.cgColor)
            if let imageView = cell.imageView {
                let image = calendarColor.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
                imageView.image = image
                imageView.layer.cornerRadius = 12.5
                imageView.layer.masksToBounds = true
            }
        case .Google:
            let googleCalendar = calendar as! GoogleCalendar
            let googleAccount = googleCalendar.account as! GoogleAccount
            cell.textLabel?.text = googleCalendar.calendar.summary
            cell.detailTextLabel?.text = googleAccount.user.profile.email
            if let colorId = googleCalendar.calendar.colorId,
                let colors = googleAccount.colors.calendar?.jsonValue(forKey: colorId) as? [String: String],
                let color = colors["background"] {
                let hex = color.replacingOccurrences(of: "#", with: "")
                let calendarColor = UIColor(hex: hex)
                let image = calendarColor.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
                cell.imageView?.image = image
                cell.imageView?.layer.cornerRadius = 12.5
                cell.imageView?.layer.masksToBounds = true
            }
            
        }
        return cell
    }
    
}

extension UIColor {
    
    func image(forRect rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { assertionFailure(); return UIImage() }
        // bitmapを塗りつぶし
        context.setFillColor(cgColor)
        context.fill(rect)
        // UIImageに変換
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { assertionFailure(); return UIImage() }
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat) {
        if hex.count == 6 {
            let rawValue: Int = Int(hex, radix: 16) ?? 0
            let B255: Int = rawValue % 256
            let G255: Int = ((rawValue - B255) / 256) % 256
            let R255: Int = ((rawValue - B255) / 256 - G255) / 256
            
            self.init(red: CGFloat(R255) / 255, green: CGFloat(G255) / 255, blue: CGFloat(B255) / 255, alpha: alpha)
        } else {
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
        }
    }
    convenience init(hex: String) {
        self.init(hex: hex, alpha: 1.0)
    }
}
