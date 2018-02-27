//
//  OpengraphIOAPI.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/20.
//

import Foundation
import Moya

struct AppID {
    let id: String
}

enum OpenGraphIOAPI {
    case site(url: URL)
}

extension OpenGraphIOAPI: TargetType {
    var sampleData: Data {
        fatalError()
    }

    var headers: [String: String]? {
        return nil
    }

    var baseURL: URL {
        return URL(string: "https://opengraph.io/api/1.1")!
    }

    var path: String {
        switch self {
        case let .site(url):
            let p = url.absoluteString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            return "site/\(p)"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .site:
            return .requestPlain
        }
    }
}
