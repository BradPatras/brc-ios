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

	/// Fetch configs from either the local cache or the remote url
	/// url provided in the class initializer.  Locally cached configs will be
	/// used if they exist and are not expired. Remote configs will be fetched
	/// otherwise or if `ignoreCache` is `true`.
	/// If configs are fetched successfully and contain a **version** value
	/// different from what is currently stored, the new configs will be assigned to the
	/// **values** class property.
	///
	/// - Parameter ignoreCache: If `true`, ignore the local cache and set new configs from
	public func fetchConfigs(ignoreCache: Bool = false) async throws {
		if !ignoreCache, cacheHelper.isCacheValid(expirationHours: cacheExpirationHours) {
			try fetchLocalConfigs()
		} else {
			do {
				try await fetchRemoteConfigs()
			} catch {
				try fetchLocalConfigs()
			}
		}
	}

	/// Clear the locally cached configs, if any exist. The next call
	/// made to `fetchConfigs()` will be guaranteed to pull configs
	/// from the remoteURL.
	public func clearCachedConfigs() {
		try? cacheHelper.deleteCache()
		version = noneVersion
		fetchDate = nil
		values = [:]
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
		let data = try await requestHelper.makeRequest(url: remoteURL) ?? Data()
		
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

	public static func mocked(configs: [String: Any]) throws -> BasicRemoteConfigs {
		let data = try JSONSerialization.data(withJSONObject: configs)
		let brc = BasicRemoteConfigs(
			remoteURL: URL(fileURLWithPath: ""),
			cacheHelper: .unimplemented,
			requestHelper: .mocked(response: data)
		)

		return brc
	}
}
