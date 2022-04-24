import Foundation

struct CacheHelper {
	private let cacheFilename: String
	private let fileManager: FileManager

	init(cacheFilename: String, fileManager: FileManager) {
		self.cacheFilename = cacheFilename
		self.fileManager = fileManager
	}

	func setCacheConfigs(configs: [String: Any]) async throws {
		guard let cacheURL = getCacheFileURL() else { return } // TODO: throw error
		
		let data = try JSONSerialization.data(withJSONObject: configs)
		try data.write(to: cacheURL)
	}
	
	func getCacheConfigs() throws -> [String: Any]? {
		guard let cacheData = try getCacheFileData() else { return nil }
		return try JSONSerialization.jsonObject(with: cacheData) as? [String: Any]
	}

	func getLastModified() throws -> Date? {
		guard let cacheURL = getCacheFileURL() else { return nil }
		
		let attributes = try fileManager.attributesOfItem(atPath: cacheURL.path)
		return (attributes[.modificationDate] ?? attributes[.creationDate]) as? Date
	}
	
	func isCacheValid(expirationHours: Int) -> Bool {
		guard let lastModified = try? getLastModified(),
			  let cachePath = getCacheFileURL()?.path
		else { return false }

		let fileExists = fileManager.fileExists(atPath: cachePath)
		let fileNotExpired = Date().isBefore(date: lastModified.adding(hours: expirationHours))
		
		return fileNotExpired && fileExists
	}
	
	private func getCacheFileData() throws -> Data? {
		guard let cacheURL = getCacheFileURL() else { return nil }
		
		return fileManager.contents(atPath: cacheURL.path)
	}
	
	private func getCacheFileURL() -> URL? {
		guard let deviceCacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		else { return nil }
		
		return deviceCacheURL.appendingPathComponent(cacheFilename, isDirectory: false)
	}
}
