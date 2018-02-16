//
//  NavigationControllerForApp.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/12.
//

import Foundation
import UIKit

struct NavigationManager: NavigationManagerType {
    
    func navigationToLoginViewController(current: UINavigationController) {
        let reactor = LoginReactor(ServiceProvider.serviceProvider)
        let viewController = LoginViewController(reactor)
        current.pushViewController(viewController, animated: true)
    }
    
}
