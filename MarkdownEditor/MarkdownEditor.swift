//
//  MarkdownEditor.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import SwiftUI
import Combine

struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    
    typealias NSViewType = MarkdownEditorView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> MarkdownEditorView {
        let markdownEditorView = MarkdownEditorView(text: text)
        markdownEditorView.delegate = context.coordinator
        return markdownEditorView
    }
    
    func updateNSView(_ nsView: MarkdownEditorView, context: Context) {
        
    }
}

// MARK: - Coordinator

extension MarkdownEditor {
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditor
        
        init(_ parent: MarkdownEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if let text = textView.textStorage?.string {
                let scanner = Scanner(source: text)
                let blocks = scanner.getBlocks()
                for block in blocks {
                    let blockColor: NSColor
                    switch block.type {
                    case .thematic_break:
                        blockColor = NSColor.orange
                    case .atx_heading:
                        blockColor = NSColor.red
                    case .setext_heading:
                        blockColor = NSColor.red
                    case .indented_code_block:
                        blockColor = NSColor.gray
                    case .fenced_code_block:
                        blockColor = NSColor.gray
                    case .block_quote:
                        blockColor = NSColor.blue
                    default:
                        blockColor = NSColor.black
                    }
                    let start = block.start.utf16Offset(in: scanner.source)
                    let end = block.end.utf16Offset(in: scanner.source)
                    let length = end - start + 1
                    textView.textStorage?.addAttribute(.foregroundColor, value: blockColor, range: NSRange(location: start, length: length))
                }
                self.parent.text = text
            }
        }
    }
}

// MARK: - MarkdownEditorView
class MarkdownEditorView: NSView {
    var text: String {
        didSet {
            textView.string = text
        }
    }
    
    weak var delegate: NSTextViewDelegate?
    
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = false
        scrollView.autoresizingMask = [.width, .height]
        return scrollView
    }()
    
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.autoresizingMask = .width
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.delegate = self.delegate
        textView.drawsBackground = true
        textView.font = NSFont(name: "Courier", size: 16.0)
        textView.isEditable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textColor = NSColor.labelColor
        textView.allowsUndo = true
        return textView
    }()
    
    init(text: String) {
        self.text = text
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDraw() {
        super.viewWillDraw()
        scrollView.documentView = textView
        addSubview(scrollView)
        setupScrollViewConstraints()
    }
    
    func setupScrollViewConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
}
