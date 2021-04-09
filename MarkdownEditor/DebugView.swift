//
//  DebugView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 08/04/2021.
//

import SwiftUI

struct DebugView: View {
    var text: String
    var body: some View {
        ScrollView {
            VStack {
                Text(debugText())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(Font.custom("Courier", size: 14.0))
                Spacer()
            }
        }
        .background(Color.white)
    }
    
    func debugText() -> String {
        let scanner = Markdown(text)
        return scanner.getDebugInfo()
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView(text: "Test")
    }
}
