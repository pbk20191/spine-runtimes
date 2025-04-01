//
//  Spine_C_ExampleApp.swift
//  Spine C Example
//
//  Created by 박병관 on 4/1/25.
//

import SwiftUI
import SpineSwift

@main
struct Spine_C_ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    NavigationLink {
                        SpineMTKSwiftUIView.init(atlasURL: Bundle.main.url(forResource: "coin-pma", withExtension: "atlas")!, jsonURL: Bundle.main.url(forResource: "coin-pro", withExtension: "json")!, animationName: "animation")
                    } label: {
                        Text("coin-pma")
                    }
                    NavigationLink {
                        SpineMTKSwiftUIView.init(atlasURL: Bundle.main.url(forResource: "tank-pma", withExtension: "atlas")!, jsonURL: Bundle.main.url(forResource: "tank-pro", withExtension: "json")!, animationName: "shoot")
                    } label: {
                        Text("tank-shoot")
                    }
                }
            }
        }
    }
}
