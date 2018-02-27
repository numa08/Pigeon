//
//  NSItemProvider+Observer.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/20.
//

import Foundation
import RxSwift

extension NSItemProvider {
    enum Errors: Error {
        case InvalidTypeError
    }

    func loadItemAsync<T>(forTypeIdentifier typeIdentifier: String, options: [AnyHashable: Any]? = nil) -> Observable<T> {
        return Observable<T>.create({ emitter -> Disposable in
            self.loadItem(forTypeIdentifier: typeIdentifier, options: options, completionHandler: { data, error in
                if let error = error {
                    emitter.onError(error)
                    return
                }
                guard let result: T = data as? T else {
                    emitter.onError(Errors.InvalidTypeError)
                    return
                }
                emitter.onNext(result)
                emitter.onCompleted()
            })
            return Disposables.create()
        })
    }
}
