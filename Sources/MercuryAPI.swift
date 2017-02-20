//
//  Mercury.swift
//  Mercury
//
//  Created by Alex Corcoran on 2/20/17.
//  Copyright © 2017 UptownApps. All rights reserved.
//
//  MIT License
//
//  Copyright (c) 2017
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public protocol MercuryAPI {
    associatedtype EndpointType: EndpointConvertible
    associatedtype ErrorType: SwiftErrorConvertible
    associatedtype TransformType: DataTransformable
    
    // Required.
    // The base url which endpoint paths are appended to.
    static var baseURL: URL { get }
    
    // Optional.
    // A hook to add API keys, authentication tokens, etc to every request when it's created.
    static func customize(request: Request)
}

public protocol EndpointConvertible {
    var path: String { get }
}

public protocol DataTransformable {
    static func transform(data: Data?) -> Self?
}

public protocol SwiftErrorConvertible: Swift.Error {
    init?(_ error: Swift.Error?)
}

// MARK: - Default Implementation

extension MercuryAPI {
    public static func customize(request: Request) {}
}

// MARK: - Requests

public typealias Request = NSMutableURLRequest

extension MercuryAPI {
    public static func createRequest(endpoint: EndpointType, queryParameters parameters: [String : String] = [:]) -> Request {
        let url = baseURL.appendingPathComponent(endpoint.path)
        let requestURL = URLComponents(fullURL: url, parameters: parameters)!.url
        
        let request = NSMutableURLRequest(url: requestURL!)
        customize(request: request)
        return request
    }
}

extension Request {
    @discardableResult
    public func setMethod(_ method: HTTPMethod) -> Self {
        httpMethod = method.rawValue
        return self
    }
    
    @discardableResult
    public func addAuthorization(_ authorization: String) -> Self {
        addValue(authorization, forHTTPHeaderField: "Authorization")
        return self
    }
    
    @discardableResult
    public func addHeaderValue(_ value: String, forField field: String) -> Self {
        addValue(value, forHTTPHeaderField: field)
        return self
    }
    
    @discardableResult
    public func setBody(_ body: Data?) -> Self {
        httpBody = body
        return self
    }
    
    @discardableResult @nonobjc
    public func setBody(_ body: [String: Any]) -> Self {
        httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        return self
    }
    
    @discardableResult @nonobjc
    public func setBody(_ body: [[String: Any]]) -> Self {
        httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        return self
    }
}

// MARK: - Fetch the Request

extension MercuryAPI {
    @discardableResult
    public static func fetch(_ request: Request, completion: @escaping (TransformType?, ErrorType?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            completion(TransformType.transform(data: data), ErrorType(error))
        }
        
        task.resume()
        
        return task
    }
}

// MARK: - Tied Types

public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case delete  = "DELETE"
    case put     = "PUT"
    case update  = "UPDATE"
    case options = "OPTIONS"
    case head    = "HEAD"
    case trace   = "TRACE"
    case connect = "CONNECT"
    case patch   = "PATCH"
}

// MARK: - Built-in Data Transformers

extension Data: DataTransformable {
    public static func transform(data: Data?) -> Data? {
        return data
    }
}

extension Dictionary: DataTransformable {
    public static func transform(data: Data?) -> Dictionary? {
        guard let data = data else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? Dictionary
    }
}

extension Array: DataTransformable {
    public static func transform(data: Data?) -> Array? {
        guard let data = data else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? Array
    }
}

// MARK: - Simple Error Type

public enum Error: CustomStringConvertible, SwiftErrorConvertible {
    case unknown
    case swift(Swift.Error?)
    
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .swift(let error): return "Swift Error: \(error?.localizedDescription)"
        }
    }
    
    public init?(_ error: Swift.Error?) {
        guard let error = error else { return nil }
        self = .swift(error)
    }
}

// MARK: - Private Convenience Extensions

extension URLComponents {
    fileprivate init?(fullURL: URL, parameters: [String : String]) {
        self.init(url: fullURL, resolvingAgainstBaseURL: true)
        let qs = parameters.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        query = qs.isEmpty ? nil : qs
    }
}
