//
//  WebView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 08/04/2021.
//

import WebKit
import SwiftUI

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
