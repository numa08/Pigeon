//
//  File.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import ReactorKit
import RxSwift
import UIKit

public class CalendarListCell:
    UITableViewCell,
    View {
    public typealias Reactor = CalendarCellReactor
    public var disposeBag: DisposeBag = DisposeBag()

    public func bind(reactor: CalendarCellReactor) {
        textLabel?.text = reactor.currentState.title
        detailTextLabel?.text = reactor.currentState.detail
        let color = reactor.currentState.color
        if let imageView = imageView {
            let image = color.image(forRect: CGRect(x: 0, y: 0, width: 25, height: 25))
            imageView.image = image
            imageView.layer.cornerRadius = 12.5
            imageView.layer.masksToBounds = true
        }
    }
}
