import Foundation

struct CacheHelper {
	private let cacheFilename: String
	
	func setCacheConfigs(configs: [String: Any]) async throws {
		guard let cacheURL = getCacheFileURL() else { return } // TODO: throw error
		
		let data = try JSONSerialization.data(withJSONObject: configs)
		try data.write(to: cacheURL)
	}
	
	func getCacheConfigs() async throws -> [String: Any]? {
		guard let cacheURL = getCacheFileURL(),
			  let data = FileManager.default.contents(atPath: cacheURL.path)
		else { return nil }
		
		return try JSONSerialization.jsonObject(with: data) as? [String: Any]
	}

	func getLastModified() throws -> Date? {
		guard let cacheURL = getCacheFileURL() else { return nil }
		
		let attributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)
		return (attributes[.modificationDate] ?? attributes[.creationDate]) as? Date
	}
	
	private func getCacheFileData() throws -> Data? {
		guard let cacheURL = getCacheFileURL() else { return nil }
		
		return try FileManager.default.contents(atPath: cacheURL.path)
	}
	
	private func getCacheFileURL() -> URL? {
		guard let deviceCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
		else { return nil }
		
		return deviceCacheURL.appendingPathComponent(cacheFilename, isDirectory: false)
	}
}
