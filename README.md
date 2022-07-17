[![spm version](https://img.shields.io/badge/Swift%20Package%20Manager-0.1.0-blue)](https://github.com/BradPatras/brc-ios/releases)

# brc-ios
Bare-bones remote configs for iOS.  Check out the [basic-remote-configs](https://github.com/BradPatras/basic-remote-configs) project repo for more context.

🚧 &nbsp; Under active development &nbsp; 🚧

### Swift Package Manager:
Either add it via `File -> Add Package` or in your `Package.swift` file:
```swift
https://github.com/BradPatras/brc-ios
```

## Usage
The usage is pretty straightforward:
1. Create an instance of BasicRemoteConfigs
2. Call `.fetchConfigs()`. (This is an `async` function so you'll need to call it with await)
3. Access your configs.
```swift
let configUrl = URL(string: "https://github.com/BradPatras/basic-remote-configs/raw/main/examples/simple.json")!

// #1
let brc = BasicRemoteConfigs(configURL: configUrl)

// ...
try await brc.fetchConfigs() // #2
let someFlag = brc.values["someFlag"] as? Bool // #3
```

## Caching
Configs are stored locally in the app's private storage once they've been fetched from the network.  Calling `.fetchConfigs()` will fetch the locally cached version of configs if either of the following are true:
1. The cache exists and is not expired (cache expires after one day)
2. The call to fetch configs from the network failed for any reason.


If you'd like to bypass the cached version and fetch the latest configs from the network, there's an optional param available.
```swift
brc.fetchConfigs(ignoreCache: Boolean)
```

## Error handling
The call to `.fetchConfigs()` may make a network request and do some deserialization, so it's bound to fail at some point. BasicRemoteConfigs will print errors under the key "BasicRemoteConfigs" using `Log.e` with a hint as to where the error happened in regards to fetching configs. It won't do any handling or masking of the exceptions so you need to wrap it in a try/catch or use a CoroutineExceptionHandler yourself.
```swift
do {
    try await brc.fetchConfigs()
} catch {
    // What happens here is up to you
}
```
