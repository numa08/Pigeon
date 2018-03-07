//
//  URLMeta.swift
//  Pigeon-iOS
//
//  Created by numa08 on 2018/03/08.
//

import Foundation
import Moya

enum URLMetaAPI {
    case meta(url: URL)
}

extension URLMetaAPI: TargetType {
    var sampleData: Data {
        fatalError()
    }

    var headers: [String: String]? {
        return nil
    }

    var baseURL: URL {
        return URL(string: "https://api.urlmeta.org")!
    }

    var path: String {
        switch self {
        case .meta:
            return "/"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case let .meta(url):
            var params: [String: String] = [:]
            params["url"] = url.absoluteString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
}
