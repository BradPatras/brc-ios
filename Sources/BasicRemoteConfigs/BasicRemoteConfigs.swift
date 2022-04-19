import Foundation

private let noneVersion = -1
private let versionKey = "ver"
private let cacheFilename = "brc_cache"
private let cacheExpirationDays = 1

public struct BasicRemoteConfigs {
	private let remoteURL: URL
	
	/// Dictionary containing the config values.
	public private(set) var values: [String: Any] = [:]
	
	/// Version parsed from the fetched configs.  If configs haven't been fetched or
	/// there was no version key included, the version will default to *-1*.
	public private(set) var version: Int = noneVersion
	
	/// A Date representing the last time the configs were successfully fetched and updated.
	public private(set) var fetchDate: Date? = nil
	
	public init(remoteURL: URL) {
		self.remoteURL = remoteURL
	}
	
	public func fetchConfigs(ignoreCache: Bool = false) async {
		
	}
	
	private func fetchLocalConfigs() async {
		
	}
	
	private func fetchRemoteConfigs() async {
		
	}
}
