//
//  ContentView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import SwiftUI

struct ContentView: View {
    @State var text = ""
    var body: some View {
        VStack {
            MarkdownEditor(text: $text)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
