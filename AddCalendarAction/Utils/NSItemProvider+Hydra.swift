//
//  NSItemProvider+Hydra.swift
//  AddCalendarAction
//
//  Created by numa08 on 2018/01/07.
//

import Foundation
import Hydra

enum NSItemProviderError: Error {
    case EmptyDataError
}

extension NSItemProvider {
    
    func loadItem(forTypeIdentifier typeIdentifier: String, options: [AnyHashable : Any]? = nil) -> Promise<NSSecureCoding> {
        return Promise(in: .background) { (resolve, reject, _) in
            self.loadItem(forTypeIdentifier: typeIdentifier, options: options, completionHandler: { (data, error) in
                if let error = error {
                    reject(error)
                    return
                }
                guard let d = data else {
                    reject(NSItemProviderError.EmptyDataError)
                    return
                }
                resolve(d)
            })
        }
    }
    
}
