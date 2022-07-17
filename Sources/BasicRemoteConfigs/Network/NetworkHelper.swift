import Foundation

struct NetworkRequestHelper {
	private let makeRequestClosure: (URL, [String: String]) async throws -> Data?

	func makeRequest(url: URL, customHeaders: [String: String]) async throws -> Data? {
		try await makeRequestClosure(url, customHeaders)
	}
}

extension NetworkRequestHelper {
	static var live: NetworkRequestHelper {
		let urlSession: URLSession = .shared

		return NetworkRequestHelper { url, customHeaders in
			var request = URLRequest(url: url)
			customHeaders.forEach { key, value in request.setValue(value, forHTTPHeaderField: key) }
			let (data, _) = try await urlSession.data(for: request)
			return data
		}
	}

	static var unimplemented: NetworkRequestHelper {
		return .init { _, _ in nil }
	}

	static func mocked(response: Data) -> NetworkRequestHelper {
		return .init { _, _ in
			return response
		}
	}
}
