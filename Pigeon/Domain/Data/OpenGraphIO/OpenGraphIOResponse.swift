// To parse the JSON, add this file to your project and do:
//
//   let openGraphIOResponse = try OpenGraphIOResponse(json)

import Foundation

struct OpenGraphIOResponse: Codable {
    let id: String?
    let hybridGraph: HTMLInferred
    let openGraph: OpenGraph?
    let htmlInferred: HTMLInferred
    let url: String
    let v: Int
    let requestInfo: RequestInfo
    let accessed: Int
    let updated: String
    let created: String
    let version: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case hybridGraph
        case openGraph
        case htmlInferred
        case url
        case v = "__v"
        case requestInfo
        case accessed
        case updated
        case created
        case version
    }
}

struct HTMLInferred: Codable {
    let images: [String]?
    let siteName: String?
    let favicon: String?
    let url: String?
    let image: String?
    let type: String?
    let description: String?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case images
        case siteName = "site_name"
        case favicon
        case url
        case image
        case type
        case description
        case title
    }
}

struct OpenGraph: Codable {
    let title: String?
    let description: String?
    let type: String?
    let image: Image?
    let url: String?
    let siteName: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case type
        case image
        case url
        case siteName = "site_name"
    }
}

struct Image: Codable {
    let url: String

    enum CodingKeys: String, CodingKey {
        case url
    }
}

struct RequestInfo: Codable {
    let host: String
    let redirects: Int

    enum CodingKeys: String, CodingKey {
        case host
        case redirects
    }
}

// MARK: Convenience initializers

extension OpenGraphIOResponse {
    init(data: Data) throws {
        self = try JSONDecoder().decode(OpenGraphIOResponse.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try jsonData(), encoding: encoding)
    }
}

extension HTMLInferred {
    init(data: Data) throws {
        self = try JSONDecoder().decode(HTMLInferred.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try jsonData(), encoding: encoding)
    }
}

extension OpenGraph {
    init(data: Data) throws {
        self = try JSONDecoder().decode(OpenGraph.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try jsonData(), encoding: encoding)
    }
}

extension Image {
    init(data: Data) throws {
        self = try JSONDecoder().decode(Image.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try jsonData(), encoding: encoding)
    }
}

extension RequestInfo {
    init(data: Data) throws {
        self = try JSONDecoder().decode(RequestInfo.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try jsonData(), encoding: encoding)
    }
}
