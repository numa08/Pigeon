//
//  CalendarRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import Foundation
import Google
import GoogleSignIn
import GoogleAPIClientForREST

protocol GoogleCalendarRepository {
    var calendarService: GTLRCalendarService { get }
    var accountRepository: GoogleAccountRepository { get }
    func fetchCalendarList(uiDelegate: GIDSignInUIDelegate, completion: @escaping ([GTLRCalendar_CalendarListEntry], Error?) -> Void)
}

extension GoogleCalendarRepository {
    
    func fetchCalendarList(uiDelegate: GIDSignInUIDelegate, completion: @escaping ([GTLRCalendar_CalendarListEntry], Error?) -> Void) {
        if let authorizer = accountRepository.authorizer {
            fetchCalendarList(forAuthorizer: authorizer, completion: completion)
            return
        }
        accountRepository.signIn(uiDelegate: uiDelegate, completion: {error in
            if let error = error {
                completion([], error)
                return
            }
            guard let authorizer = self.accountRepository.authorizer else {
                fatalError("accountRepository doesn't signin")
            }
            self.fetchCalendarList(forAuthorizer: authorizer, completion: completion)
        })
    }
    
    private func fetchCalendarList(forAuthorizer authorizer: GTMFetcherAuthorizationProtocol, completion: @escaping ([GTLRCalendar_CalendarListEntry], Error?) -> Void){
        self.calendarService.authorizer = authorizer
        let query = GTLRCalendarQuery_CalendarListList.query()
        query.minAccessRole = "writer"
        self.calendarService.executeQuery(query) { (_, response, error) in
            if let error = error {
                completion([], error)
                return
            }
            guard let list = response as? GTLRCalendar_CalendarList,
                let items = list.items else {
                fatalError("unknown response")
            }
            
            completion(items, nil)
        }
    }
}

struct DefaultGoogleCalendarRepository: GoogleCalendarRepository {
    
    static let shared: DefaultGoogleCalendarRepository = {
        return DefaultGoogleCalendarRepository()
    }()
    
    let calendarService: GTLRCalendarService = GTLRCalendarService()
    let accountRepository: GoogleAccountRepository
    
    init(injector: () -> GoogleAccountRepository = { DefaultGoogleAccountRepository.shared }) {
        self.accountRepository = injector()
    }
}
