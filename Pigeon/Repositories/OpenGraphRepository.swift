//
//  OpenGraphRepository.swift
//  Pigeon
//
//  Created by numa08 on 2017/12/26.
//

import Foundation
import Hydra

protocol OpenGraphRepository {
    func openGraph(forURL url: URL) -> Promise<OpenGraph>
}

public enum OpenGraphResponseError: Error {
    case unexpectedStatusCode(Int)
}
public enum OpenGraphParseError: Error {
    case encodingError
}

extension OpenGraphRepository {
    
    func handleHttpGET(data: Data?, response: URLResponse?, error: Error?, callback: @escaping (OpenGraph?, Error?) -> Void) {
        switch (data, response, error) {
        case (_, _, let error?):
            callback(nil, error)
            break
        case (let data?, let response as HTTPURLResponse, _):
            if !(200..<300).contains(response.statusCode) {
                callback(nil, OpenGraphResponseError.unexpectedStatusCode(response.statusCode))
            } else {
                guard let htmlString = String(data: data, encoding: String.Encoding.utf8) else {
                    callback(nil, OpenGraphParseError.encodingError)
                    return
                }
                
                let og = OpenGraphImpl(htmlString: htmlString)
                callback(og, error)
            }
            break
        default:
            break
        }
    }
}

protocol OpenGraph {
    subscript(meta: OpenGraphMetadata) -> String? { get }
}

struct OpenGraphImpl: OpenGraph {
    private let meta: [OpenGraphMetadata: String]
    
    init(withMeta meta: [OpenGraphMetadata: String]) {
        self.meta = meta
    }
    
    init(htmlString: String, injector: () -> OpenGraphParser = { DefaultOpenGraphParser() }) {
        let parser = injector()
        self.meta = parser.parse(htmlString: htmlString)
    }
    
    subscript(meta: OpenGraphMetadata) -> String? {
        get {
            return self.meta[meta]
        }
    }
}

struct HttpOpenGraphRepository: OpenGraphRepository {
    
    static let shared: OpenGraphRepository = {
        return HttpOpenGraphRepository()
    }()
    
    func openGraph(forURL url: URL) -> Promise<OpenGraph> {
        return Promise(in: .background) { (resolve, reject, _) in
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
                self.handleHttpGET(data: data, response: response, error: error, callback: {(og, error) in
                    if let error = error {
                        reject(error)
                        return
                    }
                    resolve(og!)
                })
            })
            task.resume()
        }
    }
    
    func openGraph(forURL url: URL, completion:@escaping (OpenGraph?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
            self.handleHttpGET(data: data, response: response, error: error, callback: completion)
        })
        task.resume()
    }
}
