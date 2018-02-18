//
//  CalendarListViewController.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/28.
//

import Eureka
import ReactorKit
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

open class CalendarListViewController:
    UITableViewController,
    TypedRowControllerType,
    View {
    public typealias Reactor = CalendarListReactor

    public var disposeBag: DisposeBag = DisposeBag()
    public var onDismissCallback: ((UIViewController) -> Void)?
    public var row: RowOf<CalendarCellValue>!
    public let dataSource = RxTableViewSectionedReloadDataSource<CalendarSection>(configureCell: { _, tableView, _, reactor in
        let cell: CalendarListCell = {
            if let cell = tableView.dequeueReusableCell(withIdentifier: reactor.currentState.id.value) as? CalendarListCell {
                return cell
            }
            return CalendarListCell(style: .subtitle, reuseIdentifier: reactor.currentState.id.value)
        }()
        cell.reactor = reactor
        return cell
    })
    var navigationManager: NavigationManagerType = NavigationManager()

    init(_ reactor: CalendarListReactor) {
        super.init(style: .grouped)
        self.reactor = reactor
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        if let reactor = reactor {
            Observable
                .just(Reactor.Action.loadCalendarSections)
                .bind(to: reactor.action)
                .disposed(by: disposeBag)

            Observable
                .just(onDismissCallback)
                .map { cb -> Reactor.Action in
                    if let _ = cb {
                        return Reactor.Action.setTitle("カレンダーを選択")
                    } else {
                        return Reactor.Action.setTitle("カレンダー一覧")
                    }
                }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)

            Observable
                .just(onDismissCallback)
                .map { cb -> Reactor.Action in
                    Reactor.Action.setShowAddCalendarButton(cb == nil)
                }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)

            Observable
                .just(Reactor.Action.refreshCalendars)
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
    }

    public func bind(reactor: CalendarListReactor) {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.rx.itemSelected
            .map { Reactor.Action.selectedCalendar($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        dataSource.titleForHeaderInSection = { dataSource, section in
            dataSource[section].section.name
        }

        reactor.state.asObservable().map { $0.title }
            .subscribe(onNext: { self.title = $0 })
            .disposed(by: disposeBag)
        reactor.state.asObservable().map { $0.calendarSections }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        reactor.state.asObservable().map { $0.showAddCalendarButton }
            .subscribe(onNext: { showAddCalendarButton in
                if showAddCalendarButton {
                    let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.addCalendar))
                    self.navigationItem.rightBarButtonItem = button
                } else {
                    self.navigationItem.rightBarButtonItem = nil
                }
            })
            .disposed(by: disposeBag)
        reactor.state.asObservable().map { $0.selectedCalendar }.filter { $0 != nil }.map { $0! }
            .subscribe(onNext: { provider, cell in
                let calendar = cell.initialState
                let value = CalendarCellValue(provider: provider, calendar: calendar)
                self.row?.value = value
                self.row?.updateCell()
                self.onDismissCallback?(self)
            })
            .disposed(by: disposeBag)
    }

    @objc private func addCalendar(sender _: Any) {
        if let navigationController = self.navigationController {
            navigationManager.navigationToLoginViewController(current: navigationController)
        }
    }
}

extension CalendarListViewController {
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
