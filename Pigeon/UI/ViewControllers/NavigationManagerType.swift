//
//  NavigationController.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import UIKit

protocol NavigationManagerType {
    func navigationToLoginViewController(current: UINavigationController)
    func navigationToAddCalendarCancell(current: UIViewController)
    func navigationToOnCompleteEventRegister(current: UIViewController)
}
