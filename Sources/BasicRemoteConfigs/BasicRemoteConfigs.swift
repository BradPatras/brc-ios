import Foundation

private let noneVersion = -1
private let versionKey = "ver"
private let cacheFilename = "brc_cache"
private let cacheExpirationHours = 24

public class BasicRemoteConfigs {
	private let remoteURL: URL
	private let cacheHelper: CacheHelper
	
	/// Dictionary containing the config values.
	public private(set) var values: [String: Any] = [:]
	
	/// Version parsed from the fetched configs.  If configs haven't been fetched or
	/// there was no version key included, the version will default to *-1*.
	public private(set) var version: Int = noneVersion
	
	/// A Date representing the last time the configs were successfully fetched and updated.
	public private(set) var fetchDate: Date? = nil
	
	public convenience init(remoteURL: URL) {
		self.init(
			remoteURL: remoteURL,
			cacheHelper: CacheHelper(cacheFilename: cacheFilename, fileManager: FileManager.default)
		)
	}
	
	internal init(
		remoteURL: URL,
		cacheHelper: CacheHelper
	) {
		self.remoteURL = remoteURL
		self.cacheHelper = cacheHelper
	}
	
	public func fetchConfigs(ignoreCache: Bool = false) async throws {
		if cacheHelper.isCacheValid(expirationHours: cacheExpirationHours) {
			try await fetchLocalConfigs()
		} else {
			try await fetchRemoteConfigs()
		}
	}
	
	private func fetchLocalConfigs() async throws {
		guard let newValues = try cacheHelper.getCacheConfigs() else {
			return // TODO: throw error
		}

		let newVersion = newValues[versionKey] as? Int ?? noneVersion
		guard newVersion != version || newVersion == noneVersion else { return }
		
		values = newValues
		version = newVersion
	}
	
	private func fetchRemoteConfigs() async throws {
		let (data, _) = try await URLSession.shared.data(from: remoteURL)
		
		guard let newValues = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
			return // TODO: throw error
		}
		
		let newVersion = newValues[versionKey] as? Int ?? noneVersion
		guard newVersion != version || newVersion == noneVersion else { return }
		
		values = newValues
		version = newVersion
		fetchDate = Date()
		try await cacheHelper.setCacheConfigs(configs: newValues)
	}
}
