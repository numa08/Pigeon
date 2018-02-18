//
//  EventTemplateRepositoryType.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/17.
//

import Foundation
import RxSwift
import MobileCoreServices

protocol EventTemplateRepositoryType {
    func acquireEventTemplateFrom(context: NSExtensionContext) -> Observable<EventTemplateEntity>
}

class EventTemplateRepository: EventTemplateRepositoryType {
    
    let openGraphParser: OpenGraphParser
 
    enum Errors: Error {
        case InvalidDataTypeAcuquired
    }
    
    init(_ openGraphParser: OpenGraphParser) {
        self.openGraphParser = openGraphParser
    }
    
    func acquireEventTemplateFrom(context: NSExtensionContext) -> Observable<EventTemplateEntity> {
        let observer = Observable<NSItemProvider>.create { (emitter) -> Disposable in
            let items = context.inputItems.flatMap({item -> [NSItemProvider] in
                guard let item = item as? NSExtensionItem else {
                    return []
                }
                guard let attachements = item.attachments else {
                    return []
                }
                return attachements.map { $0 as? NSItemProvider }.filter { $0 != nil }.map { $0! }
            })
            items.forEach { emitter.onNext($0) }
            return Disposables.create()
        }.flatMap { item -> Observable<NSDictionary> in
            return Observable.create({ (emitter) -> Disposable in
                if !item.hasItemConformingToTypeIdentifier((kUTTypePropertyList as String)) {
                    emitter.onNext(NSDictionary())
                    return Disposables.create()
                }
                item.loadItem(forTypeIdentifier: (kUTTypePropertyList as String), options: nil, completionHandler: {(data, error) in
                    if let error = error {
                        emitter.onError(error)
                        return
                    }
                    guard let dictionary = data as? NSDictionary,
                        let results = dictionary.object(forKey: NSExtensionJavaScriptPreprocessingResultsKey) as? NSDictionary else {
                            emitter.onError(Errors.InvalidDataTypeAcuquired)
                            return
                    }
                    emitter.onNext(results)
                })
                return Disposables.create()
            })
        }
        let uri = observer.map { $0.object(forKey: "baseURI") as? String }
        let openGraph = observer.map { $0.object(forKey: "content") as? String }.filter { $0 != nil }.map { $0! }.map { self.openGraphParser.parse(htmlString: $0) }
        return Observable.zip(uri, openGraph).map { (uri, openGraph) -> EventTemplateEntity in
            let url = URL(string: uri ?? "")
            let title = openGraph[.title]
            let description = openGraph[.description]
            return EventTemplateEntity(
                title: title,
                url: url,
                description: description
            )
        }.share(replay: 1)
    }
}

