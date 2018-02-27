//
//  ServiceProvider.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import EventKit
import Foundation
import GoogleAPIClientForREST
import GoogleSignIn
import Keys
import Moya

protocol ServiceProviderType {
    var calendarService: CalendarServiceType { get }
    var googleAccountStorage: GoogleAccountStorageType { get }
    var eventTemplateRepository: EventTemplateRepository { get }
}

struct ServiceProvider: ServiceProviderType {
    let googleAccountStorage: GoogleAccountStorageType
    let calendarService: CalendarServiceType
    let eventTemplateRepository: EventTemplateRepository

    static var serviceProvider: ServiceProviderType = {
        let userDefaults = UserDefaults.shared
        let googleAccountStorage = GoogleAccountStorage(userDefaults: userDefaults)
        let keys = PigeonKeys()
        let opengraphIOAPI: MoyaProvider<OpenGraphIOAPI> = {
            let endpointClosure = { (target: OpenGraphIOAPI) -> Endpoint in
                let url = URL(target: target)
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: url.baseURL != nil)
                var localVariable = urlComponents
                urlComponents?.queryItems = [URLQueryItem(name: "app_id", value: keys.openGraphIOAPIKey)] + (localVariable?.queryItems ?? [])
                let newUrl = urlComponents?.url?.absoluteString ?? url.absoluteString
                return Endpoint(url: newUrl, sampleResponseClosure: { .networkResponse(200, target.sampleData) }, method: target.method, task: target.task, httpHeaderFields: target.headers)
            }
            let provider = MoyaProvider(endpointClosure: endpointClosure, plugins: [NetworkLoggerPlugin(cURL: true)])
            return provider }()
        let serviceProvider = ServiceProvider(
            googleAccountStorage: googleAccountStorage,
            calendarService: CalendarService(
                eventKitCalendarRepository: EventKitCalendarRepository(eventStore: EKEventStore()), googleCalendarRepository: GoogleCalendarRepository(accountStorage: googleAccountStorage, googleService: { GTLRCalendarService() }, userDefaults: userDefaults)),
            eventTemplateRepository: EventTemplateRepository(opengraphIOAPI, DefaultOpenGraphParser()))
        return serviceProvider
    }()
}
