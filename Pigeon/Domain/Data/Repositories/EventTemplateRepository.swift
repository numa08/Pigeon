//
//  EventTemplateRepositoryType.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/17.
//

import Foundation
import MobileCoreServices
import RxSwift

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
        let providers = context.inputItems.flatMap({ item -> [NSItemProvider] in
            guard let item = item as? NSExtensionItem else {
                return []
            }
            guard let attachements = item.attachments else {
                return []
            }
            return attachements.map { $0 as? NSItemProvider }.filter { $0 != nil }.map { $0! }
        })
        
        let observer = Observable<NSItemProvider>.from(providers).flatMap { item -> Observable<NSDictionary> in
            return Observable.create({ (emitter) -> Disposable in
                if item.hasItemConformingToTypeIdentifier((kUTTypePropertyList as String)) {
                    item.loadItem(forTypeIdentifier: (kUTTypePropertyList as String), options: nil, completionHandler: { data, error in
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
                        emitter.onCompleted()
                    })
                } else if item.hasItemConformingToTypeIdentifier((kUTTypeURL as String)) {
                    item.loadItem(forTypeIdentifier: (kUTTypeURL as String), options: nil, completionHandler: { data, error in
                        if let error = error {
                            emitter.onError(error)
                            return
                        }
                        guard let url = data as? URL else {
                            emitter.onError(Errors.InvalidDataTypeAcuquired)
                            return
                        }
                        let dictionary = NSDictionary(dictionary: ["baseURI": url.absoluteString])
                        emitter.onNext(dictionary)
                        emitter.onCompleted()
                    })
                }
                return Disposables.create()
            }).share(replay: 1)
        }.share(replay: 1)
        let uri = observer.map { $0.object(forKey: "baseURI") as? String }
        let openGraph = observer.map { dict -> [OpenGraphMetadata: String] in
            if let content = dict.object(forKey: "content") as? String {
                return self.openGraphParser.parse(htmlString: content)
            } else {
                return [:]
            }
        }
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
