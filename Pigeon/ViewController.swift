//
//  ViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//  Copyright © 2017年 numa08. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let openGraphRepository: OpenGraphRepository = HttpOpenGraphRepository.shared
    private var calendarBuildViewController: CalendarBodyBuildViewController? = nil
    
    @IBOutlet weak var fetchTargetTextField: UITextField!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationVC = segue.destination as? UINavigationController else {
            fatalError("destination isn't navigationcontroller destination: \(segue.destination)")
        }
        guard let vc = navigationVC.topViewController as? CalendarBodyBuildViewController else {
            fatalError("navigationViewController's root isnt' CalendarBodyBuildViewController root: \(navigationVC.topViewController!)")
        }
        self.calendarBuildViewController = vc
    }
    
    @IBAction func didTouchFetchButton(_ sender: UIButton) {
        sender.isEnabled = false
        guard let text = fetchTargetTextField.text else {
            print("text is empty")
            return
        }
        guard let url = URL(string: text) else {
            print("invalid url")
            return
        }
        openGraphRepository.openGraph(forURL: url) { (openGraph, error) in
            DispatchQueue.main.async {
                sender.isEnabled = true
                guard let og = openGraph else {
                    print("opengraphe fetch error \(error!)")
                    return
                }
                self.calendarBuildViewController?.openGraph = og
            }
        }
    }
    
}

