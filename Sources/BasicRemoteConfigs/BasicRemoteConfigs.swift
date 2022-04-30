import Foundation

private let noneVersion = -1
private let versionKey = "ver"
private let cacheFilename = "brc_cache"
private let cacheExpirationHours = 24

public enum BasicRemoteConfigsError: LocalizedError {
	case failedToFetchLocalConfigs
	case failedToDeserializeConfigs
	
	public var errorDescription: String? {
		switch self {
		case .failedToDeserializeConfigs:
			return NSLocalizedString(
				"Failed to deserialize config data",
				comment: "Error message for when config data deserialization failed"
			)
		case .failedToFetchLocalConfigs:
			return NSLocalizedString(
				"Failed to fetch local configs",
				comment: "Error message for when local config fetch failed"
			)
		}
	}
}

public class BasicRemoteConfigs {
	private let remoteURL: URL
	private let cacheHelper: CacheHelper
	private let requestHelper: NetworkRequestHelper
	
	/// Dictionary containing the config values.
	public private(set) var values: [String: Any] = [:]
	
	/// Version parsed from the fetched configs.  If configs haven't been fetched or
	/// there was no version key included, the version will default to *-1*.
	public private(set) var version: Int = noneVersion
	
	/// A Date representing the last time the configs were successfully fetched and updated.
	public private(set) var fetchDate: Date? = nil
	
	private init(
		remoteURL: URL,
		cacheHelper: CacheHelper,
		requestHelper: NetworkRequestHelper
	) {
		self.remoteURL = remoteURL
		self.cacheHelper = cacheHelper
		self.requestHelper = requestHelper
	}

	public func fetchConfigs(ignoreCache: Bool = false) async throws {
		if cacheHelper.isCacheValid(expirationHours: cacheExpirationHours) {
			try fetchLocalConfigs()
		} else {
			do {
				try await fetchRemoteConfigs()
			} catch {
				try fetchLocalConfigs()
			}
		}
	}
	
	private func fetchLocalConfigs() throws {
		guard let newValues = try cacheHelper.getCacheConfigs() else {
			throw BasicRemoteConfigsError.failedToFetchLocalConfigs
		}

		let newVersion = newValues[versionKey] as? Int ?? noneVersion
		guard newVersion != version || newVersion == noneVersion else { return }
		
		values = newValues
		version = newVersion
	}
	
	private func fetchRemoteConfigs() async throws {
		let (data, _) = try await URLSession.shared.data(from: remoteURL)
		
		guard let newValues = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
			throw BasicRemoteConfigsError.failedToDeserializeConfigs
		}
		
		let newVersion = newValues[versionKey] as? Int ?? noneVersion
		guard newVersion != version || newVersion == noneVersion else { return }
		
		values = newValues
		version = newVersion
		fetchDate = Date()
		try cacheHelper.setCacheConfigs(newValues)
	}
}

extension BasicRemoteConfigs {
	public static func live(remoteURL: URL) -> BasicRemoteConfigs {
		return .init(
			remoteURL: remoteURL,
			cacheHelper: .live(cacheFilename: cacheFilename, fileManager: FileManager.default),
			requestHelper: .live
		)
	}
	
	public static var unimplemented: BasicRemoteConfigs {
		return BasicRemoteConfigs(remoteURL: URL(fileURLWithPath: ""), cacheHelper: .unimplemented, requestHelper: .unimplemented)
	}
	
	public static func mocked(configs: [String: Any]) -> BasicRemoteConfigs {
		let brc = BasicRemoteConfigs(remoteURL: URL(fileURLWithPath: ""), cacheHelper: .unimplemented, requestHelper: .unimplemented)
		brc.values = configs
		
		return brc
	}
}
