//
//  brc_ios_demoApp.swift
//  brc-ios-demo
//
//  Created by Brad Patras on 4/24/22.
//

import BasicRemoteConfigs
import SwiftUI

@main
struct DemoApp: App {
	let brc = BasicRemoteConfigs.live(
		remoteURL: URL(
			string: "https://github.com/BradPatras/basic-remote-configs/raw/main/examples/simple.json"
		)!
	)
	
    var body: some Scene {
        WindowGroup {
            ContentView(brc: brc)
        }
    }
}
