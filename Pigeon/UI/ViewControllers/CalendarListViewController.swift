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
            return dataSource[section].section
        }
    }
}

extension CalendarListViewController {
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}


//// Eureka で使うので open とする
//open class CalendarListViewController: UITableViewController, TypedRowControllerType {
//
//    public var onDismissCallback: ((UIViewController) -> Void)?
//    public var row: RowOf<CalendarValue>!
//
//    private var dataSet: [UserAccountValue: [CalendarValue]] = [:]
//    let calendarRepository: CalendarRepository = UserDefaultsCalendarRepository(userDefaults: UserDefaults.shared)
//    let userAccountRepository: UserAccountRepository = UserDefaultsUserAccountRepository(userDefaults: UserDefaults.shared)
//
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    open override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        loadRepository()
//    }
//}
//
//extension CalendarListViewController {
//
//    func loadRepository() {
//        userAccountRepository.restore().then({ (userAccounts) -> Promise<[(UserAccount, [Calendar])]> in
//            let promises = userAccounts.map({ (account) in
//                return self.calendarRepository.restore(forAccount: account).then({ (calendars) in
//                    return (account, calendars)
//                })
//            }).filter({$0 != nil}).map({$0!})
//            return all(promises)
//        }).then(in: .main) {res in
//            res.forEach({ (account, calendars) in
//                let accountRow = account.toValue()
//                let calendarRows = calendars.map({$0.toValue()})
//                self.dataSet[accountRow] = calendarRows
//            })
//            self.tableView.reloadData()
//        }.catch({ (error) in
//            print("restore useraccount error \(error)")
//        })
//    }
//
//}
//
//extension CalendarListViewController {
//
//    func calendar(forSection section: Int, index: Int) -> CalendarValue {
//        let key = Array(dataSet.keys)[section]
//        let calendars = dataSet[key]
//        return calendars![index]
//    }
//
//    open override func numberOfSections(in tableView: UITableView) -> Int {
//        return dataSet.keys.count
//    }
//
//    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        let account = Array(dataSet.keys)[section]
//        return account.sectionHeaderFor(tableView)
//    }
//
//    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let key = Array(dataSet.keys)[section]
//        let calendars = dataSet[key]
//        return calendars!.count
//    }
//
//    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let calendar = self.calendar(forSection: indexPath.section, index: indexPath.row)
//        let cell = calendar.cellFor(tableView, rowAt: indexPath)
//        return cell
//    }
//
//    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let calendar = self.calendar(forSection: indexPath.section, index: indexPath.row)
//        row?.value = calendar
//        row?.updateCell()
//        onDismissCallback?(self)
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}

