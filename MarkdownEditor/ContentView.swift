//
//  ContentView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import SwiftUI

struct ContentView: View {
    @State var source = ""
    var body: some View {
        TabView {
            MarkdownEditor(text: $source)
                .tabItem { Text("Editor") }
                .padding()
            HTMLView(text: source)
                .tabItem { Text("HTML") }
                .padding()
            DebugView(text: source)
                .tabItem { Text("Debug") }
                .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
