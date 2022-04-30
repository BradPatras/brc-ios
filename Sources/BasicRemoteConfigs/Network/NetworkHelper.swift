import Foundation

struct NetworkRequestHelper {
	private let makeRequestClosure: (URL) async throws -> Data?
	
	func makeRequest(url: URL) async throws -> Data? {
		try await makeRequestClosure(url)
	}
}

extension NetworkRequestHelper {
	static var live: NetworkRequestHelper {
		let urlSession: URLSession = .shared
		
		return NetworkRequestHelper { url in
			let (data, _) = try await urlSession.data(from: url)
			return data
		}
	}
	
	static var unimplemented: NetworkRequestHelper {
		return .init { _ in nil }
	}
}
