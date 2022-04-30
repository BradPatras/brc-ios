//
//  ContentView.swift
//  brc-ios-demo
//
//  Created by Brad Patras on 4/24/22.
//

import BasicRemoteConfigs
import SwiftUI

struct ContentView: View {
	let brc: BasicRemoteConfigs
	@State var text: String = "Hello, world!"
	
    var body: some View {
		VStack {
			Spacer()
			
			Text(text)
				.padding()
				.font(.caption)
			
			Button(action: {
				text = "Fetching configs..."
				
				Task {
					do {
						try await brc.fetchConfigs()
						text = brc.values.prettyPrint()
					} catch {
						text = error.localizedDescription
					}
				}
			}) {
				Text("Fetch configs")
			}
			
			Spacer()
			
			ProgressView()
			
			Spacer()
		}
    }
}

extension Dictionary where Key == String, Value == Any {
	func prettyPrint() -> String{
		var string: String = ""
		if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted){
			if let nstr = NSString(data: data, encoding: String.Encoding.utf8.rawValue){
				string = nstr as String
			}
		}
		return string
	}
}
