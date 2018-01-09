//
//  CalendarSelectorRowViewController.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/09.
//

import Foundation
import UIKit
import Eureka

open class _CalendarRow: OptionsRow<PushSelectorCell<CalendarValue>>, PresenterRowType {
    public var onPresentCallback: ((FormViewController, CalendarListViewController) -> Void)?
    
    public typealias PresentedControllerType = CalendarListViewController
    public var presentationMode: PresentationMode<_CalendarRow.PresentedControllerType>?
    
    public required init(tag: String?) {
        super.init(tag: tag)
        self.presentationMode = .show(controllerProvider: ControllerProvider.callback(builder: { () -> CalendarListViewController in
            let vc = CalendarListViewController(style: .grouped)
            return vc
        })) { vc in
            let _ = vc.navigationController?.popViewController(animated: true)
        }
        self.displayValueFor = {
            return $0?.calendar.identifier
        }
    }
 
    open override func customDidSelect() {
        guard !isDisabled else {
            super.customDidSelect()
            return
        }
        deselect()
        super.customDidSelect()
        guard let presentationMode = presentationMode else { fatalError("presentationMode is nil") }
        guard let controller = presentationMode.makeController() else { fatalError("makeController return nil") }
        controller.row = self
        controller.title = selectorTitle ?? controller.title
        onPresentCallback?(cell.formViewController()!, controller)
        presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
    }
}

public final class CalendarRow: _CalendarRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
