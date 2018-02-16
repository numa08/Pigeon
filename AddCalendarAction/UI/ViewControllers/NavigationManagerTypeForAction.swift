//
//  NavigationControllerForAction.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import UIKit

struct NavigationManager: NavigationManagerType {
    func navigationToLoginViewController(current: UINavigationController) {}
    
    func navigationToAddCalendarCancell(current: UIViewController) {
        current.extensionContext!.completeRequest(returningItems: current.extensionContext!.inputItems, completionHandler: nil)
    }
    
    func navigationToOnCompleteEventRegister(current: UIViewController) {
         current.extensionContext?.completeRequest(returningItems: current.extensionContext!.inputItems, completionHandler: nil)
    }
}
