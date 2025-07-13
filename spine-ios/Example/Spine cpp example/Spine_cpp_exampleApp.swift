//
//  Spine_cpp_exampleApp.swift
//  Spine cpp example
//
//  Created by 박병관 on 7/11/25.
//

import SwiftUI

import SwiftUI
import SpineSwift
import spine_c

@main
struct Spine_C_ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    NavigationLink("blank") {
                        Text("Blank")
                    }
                    NavigationLink {
                        SpineMTKSwiftUIView2.init(atlasURL: Bundle.main.url(forResource: "tank-pma", withExtension: "atlas")!, skelURL: Bundle.main.url(forResource: "tank-pro", withExtension: "skel")!, animationName: "shoot", tag: "tank")
                    } label: {
                        Text("tank-pma")
                    }
                    NavigationLink {
                        SpineMTKSwiftUIView.init(atlasURL: Bundle.main.url(forResource: "coin-pma", withExtension: "atlas")!, jsonURL: Bundle.main.url(forResource: "coin-pro", withExtension: "json")!, animationName: "animation", tag: "coin")
                    } label: {
                        Text("coin-pma")
                    }
                    NavigationLink {
                        SpineMTKSwiftUIView.init(atlasURL: Bundle.main.url(forResource: "tank-pma", withExtension: "atlas")!, jsonURL: Bundle.main.url(forResource: "tank-pro", withExtension: "json")!, animationName: "shoot", tag:"tank")
                    } label: {
                        Text("tank-shoot")
                    }
                }
            }
        }
    }
    
    
    init () {

    }
}
