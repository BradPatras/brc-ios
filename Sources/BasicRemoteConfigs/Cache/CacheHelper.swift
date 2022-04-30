import Foundation


enum CacheHelperError: LocalizedError {
	case cacheFileURLError
	
	var errorDescription: String? {
		switch self {
		case .cacheFileURLError:
			return NSLocalizedString(
				"Failed to acquire cache file url",
				comment: "Error description for when the cache url can't be acquired"
			)
		}
	}
}

struct CacheHelper {
	private let cacheFilename: String
	private let fileManager: FileManager

	init(cacheFilename: String, fileManager: FileManager) {
		self.cacheFilename = cacheFilename
		self.fileManager = fileManager
	}

	func setCacheConfigs(configs: [String: Any]) async throws {
		let cacheURL = try getCacheFileURL()
		let data = try JSONSerialization.data(withJSONObject: configs)
		try data.write(to: cacheURL)
	}
	
	func getCacheConfigs() throws -> [String: Any]? {
		let cacheData = try getCacheFileData()
		return try JSONSerialization.jsonObject(with: cacheData) as? [String: Any]
	}
	
	func clearCache() {
		let cacheURL = try? getCacheFileURL()
		try? fileManager.removeItem(atPath: cacheURL.path)
	}

	func getLastModified() throws -> Date? {
		let cacheURL = try getCacheFileURL()
		
		let attributes = try fileManager.attributesOfItem(atPath: cacheURL.path)
		return (attributes[.modificationDate] ?? attributes[.creationDate]) as? Date
	}

	func isCacheValid(expirationHours: Int) -> Bool {
		guard let lastModified = try? getLastModified(),
			  let cachePath = try? getCacheFileURL().path
		else { return false }

		let fileExists = fileManager.fileExists(atPath: cachePath)
		let fileNotExpired = Date().isBefore(date: lastModified.adding(hours: expirationHours))
		
		return fileNotExpired && fileExists
	}
	
	private func getCacheFileData() throws -> Data? {
		let cacheURL = try getCacheFileURL()
		return fileManager.contents(atPath: cacheURL.path)
	}
	
	private func getCacheFileURL() throws -> URL {
		guard let deviceCacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		else { throw CacheHelperError.cacheFileURLError }
		
		return deviceCacheURL.appendingPathComponent(cacheFilename, isDirectory: false)
	}
}
