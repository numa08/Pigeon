
//
//  File.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/02/16.
//

import Eureka
import Foundation
import UIKit

public struct CalendarCellValue {
    let provider: CalendarProviderCellModel
    let calendar: CalendarCellModel
}

extension CalendarCellValue: Hashable {
    public static func== (lhs: CalendarCellValue, rhs: CalendarCellValue) -> Bool {
        return lhs.provider.name == rhs.provider.name
            && lhs.calendar.id == rhs.calendar.id
    }

    public var hashValue: Int {
        return provider.name.hashValue
    }
}

public class CalendarCell: PushSelectorCell<CalendarCellValue> {
    public override func update() {
        if let title = row.title {
            textLabel?.text = title
        }
        if let value = row.value {
            textLabel?.text = value.calendar.title
            detailTextLabel?.text = value.calendar.detail
            let color = value.calendar.color
            if let imageView = imageView {
                let image = color.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
                imageView.image = image
                imageView.layer.cornerRadius = 12.5
                imageView.layer.masksToBounds = true
            }
        }
    }
}

open class _CalendarRow: OptionsRow<CalendarCell>, PresenterRowType {
    public var onPresentCallback: ((FormViewController, CalendarListViewController) -> Void)?

    public typealias PresentedControllerType = CalendarListViewController
    public var presentationMode: PresentationMode<_CalendarRow.PresentedControllerType>?

    public required init(tag: String?) {
        super.init(tag: tag)
        cellStyle = UITableViewCellStyle.subtitle
        presentationMode = .show(controllerProvider: ControllerProvider.callback(builder: { () -> CalendarListViewController in
            let vc = CalendarListViewController(CalendarListReactor(ServiceProvider.serviceProvider))
            return vc
        })) { vc in
            _ = vc.navigationController?.popViewController(animated: true)
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
        presentationMode.present(controller, row: self, presentingController: cell.formViewController()!)
    }
}

public final class CalendarRow: _CalendarRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
