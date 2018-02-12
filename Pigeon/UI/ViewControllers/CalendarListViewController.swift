//
//  CalendarListViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/28.
//

import UIKit
import Eureka

import ReactorKit
import RxCocoa
import RxDataSources
import RxSwift

open class CalendarListViewController:
UITableViewController,
TypedRowControllerType,
View {
    
    public typealias Reactor = CalendarListReactor
    
    public var disposeBag: DisposeBag = DisposeBag()
    public var onDismissCallback: ((UIViewController) -> Void)?
    public var row: RowOf<String>!
    public let dataSource = RxTableViewSectionedReloadDataSource<CalendarSection>(configureCell: {_, tableView, indexPath, reactor in
        let cell: CalendarListCell = {
            if let cell = tableView.dequeueReusableCell(withIdentifier: reactor.currentState.id.value) as? CalendarListCell {
                return cell
            }
            return CalendarListCell(style:. subtitle, reuseIdentifier: reactor.currentState.id.value)
        }()
        cell.reactor = reactor
        return cell
    })
    
    init(_ reactor: CalendarListReactor) {
        super.init(style: .grouped)
        self.reactor = reactor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let reactor = reactor {
            Observable
                .just(Reactor.Action.loadCalendarSections)
                .bind(to: reactor.action)
                .disposed(by: self.disposeBag)
        }
    }
    
    public func bind(reactor: CalendarListReactor) {
        self.tableView.rx.setDelegate(self).disposed(by: disposeBag)
        self.tableView.rx.itemSelected
            .map { Reactor.Action.selectedCalendar($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        self.dataSource.titleForHeaderInSection = {dataSource, section in
            return dataSource[section].section.name
        }
    }
}

extension CalendarListViewController {
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
