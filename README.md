# Mercury
Mercury, named for the Patron God of Communication, is a simple framework written in Swift 3.0 designed to help you eloquently develop your API communication layer.

# Example
```swift

// The struct holds the values related to the API environment. This could be URLs,
// API keys, or user authentication status.

struct MyAPI {
	fileprivate static let urlBase: URL = "https://example.com"
	fileprivate static let version      = "v2"
	fileprivate static let appName      = "my-app"
	fileprivate static let appID        = "app-id"
	fileprivate static let apiKey       = "api-key"
}

// MARK: - Mercury protocol conformance

// The protocol conformance extension implements the concrete types for the typealiases.
//
// The `EndpointType` must be implemented by the developer and conform to `EndpointConvertible`
// The `ErrorType` may be set to the provided `Error` type or to any concrete type which conforms to `SwiftErrorConvertible`
// The `TransformType` may be set to any of the built-in transfomers (Data, Array<T>, Dictionary<T, E>) or to any other type which
//    conforms to `DataTransformable` such as JSON parsing libraries.
//
// The `baseURL` is the URL that all endpoints will be appended to. It's recommended to include versions, app names, etc here.
//
// The `customize` function allows you to makes changes to every request as it's created. This is useful for adding headers,
// common query parameters, etc.

extension MyAPI: MercuryAPI {
	typealias EndpointType = MyEndpoint
    typealias ErrorType = Error
    typealias TransformType = Dictionary<String, Any>

    static var baseURL: URL {
    	return urlBase.appendingPathComponent(version).appendingPathComponent(appName)
    }

    static func customize(request: Request) {
    	request.addValue(appID, forHTTPHeaderField: "app-id")
    	request.addValue(apiKey, forHTTPHeaderField: "api-key")
    	request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}

// The concrete endpoint type is recommended to be an `enum` and must confrom to `EndpointConvertible` which
// returns a string path. This path is appended to the `baseURL` when the request is created.

enum MyEndpoint: EndpointConvertible {
	case fetchAll
	case search(String)

	var path: String {
		switch self {
			case .fetchAll: return "data/fetchAll"
			case .search(let searchTerm): return "search/\(searchTerm)/results"
		}
	}
}

// MARK: - MyAPI 

extension MyAPI {
	@discardableResult
	func fetchAll(completion: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionDataTask {
		let request = createRequest(endpoint: .fetchAll)
		return fetch(request) { result, error in
			completion(result, error)
		}
	}

	// You may chain together mutation functions to set the HTTP method, add headers, set body, etc.
	// The `fetch` function takes the `Request` type and calls a completion closure with two optional
	// parameters, the first being the result matching the `TransformType`, and the second being any errors
	// matching the `ErrorType` defined above.

	@discardableResult
	func search(_ term: String, completion: @escaping () -> Void) -> URLSessionDataTask {
		let requeset = createRequest(endpoint: .search(term), parameters: ["limit": "10"])
			.setMethod(.get) // This is the default
			.setHeaderValue("", forField: "") // Function for setting header fields
			.setAuthorization("Bearer xyz") // Convenince function for setting "Authorization" header
			.setBody(_) // Useful for setting POST bodies. Can accept Data, [String: Any], [[String: Any]], or nil

		return fetch(request) { result, error in
			// ...
			completion()
		}
	} 
}

// MARK: View Controller

class MyViewController: UIViewController {
	// ...

	var results: [String: Any] = [:]
	weak var searchTask: URLSessionDataTask?

	func fetchAll() {
		MyAPI.fetchAll { [weak self] result, error in

			DispatchQueue.main.async {
				if let error = error {
					// TODO: Handle Error
				} else {
					self?.results = result
					self?.refreshUI()
				}
			}
			
		}
	}

	func search(query: String) {
		// Cancel previous search if it's still running.
		searchTask?.cancel()

		searchTask = MyAPI.search(query) {
			// ...
		}
	}
}

```

