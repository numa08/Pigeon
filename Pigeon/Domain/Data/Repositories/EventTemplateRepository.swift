//
//  EventTemplateRepositoryType.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/17.
//

import Foundation
import MobileCoreServices
import Moya
import RxMoya
import RxSwift

protocol EventTemplateRepositoryType {
    func acquireEventTemplateFrom(context: NSExtensionContext) -> Observable<EventTemplateEntity>
}

class EventTemplateRepository: EventTemplateRepositoryType {
    let openGraphParser: OpenGraphParser
    let openGraphIOAPI: MoyaProvider<OpenGraphIOAPI>

    enum Errors: Error {
        case InvalidDataTypeAcuquired
    }

    init(_ openGraphIOAPI: MoyaProvider<OpenGraphIOAPI>, _ openGraphParser: OpenGraphParser) {
        self.openGraphIOAPI = openGraphIOAPI
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
        let observers = Observable<NSItemProvider>.from(providers).flatMap { (item) -> Observable<EventTemplateEntity> in
            if item.hasItemConformingToTypeIdentifier((kUTTypePropertyList as String)) {
                let dataObserver: Observable<NSDictionary> = item.loadItemAsync(forTypeIdentifier: (kUTTypePropertyList as String))
                return dataObserver.flatMap(self.eventTemplate(fromJavaScriptHandlerResult:))
            } else if item.hasItemConformingToTypeIdentifier((kUTTypeURL as String)) {
                let dataObserver: Observable<URL> = item.loadItemAsync(forTypeIdentifier: (kUTTypeURL as String))
                return dataObserver.flatMap(self.eventTemplate(fromURL:))
            }
            fatalError()
        }
        return observers.reduce(EventTemplateEntity(title: nil, url: nil, description: nil)) { (result, entity) -> EventTemplateEntity in
            let title = entity.title ?? result.title
            let url = entity.url ?? result.url
            let description = entity.description ?? result.description
            return EventTemplateEntity(title: title, url: url, description: description)
        }.share(replay: 1)
    }

    func eventTemplate(fromJavaScriptHandlerResult result: NSDictionary) -> Observable<EventTemplateEntity> {
        return Observable.create({ (emitter) -> Disposable in
            let url = URL(string: result.object(forKey: "baseURI") as? String ?? "")
            let content = result.object(forKey: "content") as? String
            let openGraph = self.openGraphParser.parse(htmlString: content ?? "")
            let eventTemplate = EventTemplateEntity(title: openGraph[.title], url: url, description: openGraph[.description])
            emitter.onNext(eventTemplate)
            emitter.onCompleted()
            return Disposables.create()
        }).share(replay: 1)
    }

    func eventTemplate(fromURL url: URL) -> Observable<EventTemplateEntity> {
        return openGraphIOAPI.rx.request(.site(url: url))
            .asObservable()
            .map { (response) -> OpenGraphIOResponse in
                let decoder = JSONDecoder()
                return try decoder.decode(OpenGraphIOResponse.self, from: response.data) }
            .map { (response) -> EventTemplateEntity in
                let title = response.hybridGraph.title ?? response.openGraph?.title
                let description = response.hybridGraph.description ?? response.openGraph?.description
                let url = response.hybridGraph.url ?? response.openGraph?.url
                return EventTemplateEntity(title: title, url: URL(string: url ?? ""), description: description)
            }
            .catchError({ (_) -> Observable<EventTemplateEntity> in
                Observable.just(EventTemplateEntity(title: nil, url: url, description: nil))
            })
            .share(replay: 1)
    }
}
