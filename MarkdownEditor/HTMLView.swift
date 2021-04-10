//
//  HTMLView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 08/04/2021.
//

import SwiftUI
import WebKit

struct HTMLView: View {
    var text: String
    @State var viewSource = false
    var body: some View {
        VStack {
            VStack {
                if viewSource {
                    ScrollView {
                        Text(htmlText())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font.custom("Courier", size: 14.0))
                    }
                } else {
                    WebView(html: htmlText())
                }
                Spacer()
            }
            .background(Color.white)
            Toggle("View source",isOn: $viewSource)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    func htmlText() -> String {
        let scanner = Markdown(text)
        return scanner.getHtml()
    }

}

struct HTMLView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLView(text: "Test")
    }
}

struct WebView: NSViewRepresentable {
    let html: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.loadHTMLString(html, baseURL: nil)
        return webview
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}

