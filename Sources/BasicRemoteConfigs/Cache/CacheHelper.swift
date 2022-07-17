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
	private let setCacheConfigsClosure: ([String: Any]) throws -> Void

	private let getCacheConfigsClosure: () throws -> [String: Any]?

	private let getLastModifiedClosure: () throws -> Date?

	private let isCacheValidClosure: (Int) -> Bool

	private let deleteCacheClosure: () throws -> Void
	
	func setCacheConfigs(_ configs: [String: Any]) throws {
		try setCacheConfigsClosure(configs)
	}

	func getCacheConfigs() throws -> [String: Any]? {
		try getCacheConfigsClosure()
	}
	
	func getLastModified() throws -> Date? {
		try getLastModifiedClosure()
	}
	
	func isCacheValid(expirationHours: Int) -> Bool {
		isCacheValidClosure(expirationHours)
	}

	func deleteCache() throws {
		try deleteCacheClosure()
	}
}

extension CacheHelper {
	static var unimplemented: CacheHelper {
		return CacheHelper(
			setCacheConfigsClosure: { _ in },
			getCacheConfigsClosure: { nil },
			getLastModifiedClosure: { nil },
			isCacheValidClosure: { _ in false },
			deleteCacheClosure: { }
		)
	}
	
	static func live(cacheFilename: String, fileManager: FileManager) -> CacheHelper {
		func getLastModified() throws -> Date? {
			let cacheURL = try getCacheFileURL(cacheFilename: cacheFilename, fileManager: fileManager)
			
			let attributes = try fileManager.attributesOfItem(atPath: cacheURL.path)
			return (attributes[.modificationDate] ?? attributes[.creationDate]) as? Date
		}
		
		return .init(
			setCacheConfigsClosure: { configs in
				let cacheURL = try getCacheFileURL(cacheFilename: cacheFilename, fileManager: fileManager)
				let data = try JSONSerialization.data(withJSONObject: configs)
				try data.write(to: cacheURL)
			},
			getCacheConfigsClosure: {
				guard let cacheData = try getCacheFileData(cacheFilename: cacheFilename, fileManager: fileManager) else { return nil }
				return try JSONSerialization.jsonObject(with: cacheData) as? [String: Any]
			},
			getLastModifiedClosure: getLastModified,
			isCacheValidClosure: { expirationHours -> Bool in
				guard let lastModified = try? getLastModified(),
					  let cachePath = try? getCacheFileURL(cacheFilename: cacheFilename, fileManager: fileManager).path
				else { return false }

				let fileExists = fileManager.fileExists(atPath: cachePath)
				let fileNotExpired = Date().isBefore(date: lastModified.adding(hours: expirationHours))
				
				return fileNotExpired && fileExists
			},
			deleteCacheClosure: {
				guard let cachePath = try? getCacheFileURL(cacheFilename: cacheFilename, fileManager: fileManager).path
				else { return }

				try fileManager.removeItem(atPath: cachePath)
			}
		)
	}

	private static func getCacheFileData(cacheFilename: String, fileManager: FileManager) throws -> Data? {
		let cacheURL = try getCacheFileURL(cacheFilename: cacheFilename, fileManager: fileManager)
		return fileManager.contents(atPath: cacheURL.path)
	}
	
	private static func getCacheFileURL(cacheFilename: String, fileManager: FileManager) throws -> URL {
		guard let deviceCacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		else { throw CacheHelperError.cacheFileURLError }
		
		return deviceCacheURL.appendingPathComponent(cacheFilename, isDirectory: false)
	}
}
