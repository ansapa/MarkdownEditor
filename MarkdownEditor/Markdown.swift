//
//  Markdown.swift
//  Markdown parser
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//
//  Usage:
//  let markdown = Markdown(source)
//  let lines = markdown.getLines()
//  let blocks = markdown.getBlocks()
//  let nodes = markdown.getNodes()
//  let html = markdown.getHtml()
//
//  Parsing:
//  <source> -> Lines (= array of Line) -> Blocks (= array of Block) -> Nodes (= tree of Node) -> HTML

import Foundation

class Markdown {
    
    // MARK: - Public -
    
    // MARK: Properties
    let source: String
    
    // MARK: Initializers
    init(_ source: String) {
        self.source = source
    }

    // MARK: Line
    struct Line {
        let start: String.Index
        let end: String.Index
    }
    
    func getLines() -> [Line] {
        return _getLines(source)
    }
    
    // MARK: Block
    enum BlockType {
        case thematic_break
        case atx_heading
        case setext_heading
        case indented_code_block
        case fenced_code_block
        case html_block
        case link_reference_definition
        case paragraph
        case block_quote
        case list_item
        case blank_line
    }
    
    class Block {
        var start: String.Index
        var end: String.Index
        var type: BlockType
        
        init(start: String.Index, end: String.Index, type: BlockType) {
            self.start = start
            self.end = end
            self.type = type
        }
    }
    
    func getBlocks() -> [Block] {
        let lines = getLines()
        return _getBlocks(lines)
    }

    // MARK: Node
    enum NodeType {
        // Block nodes
        case document
        case block_quote
        case list
        case item
        case code_block
        case paragraph
        case heading
        case thematic_break
        case html_block
        // Inline nodes
        case text
        case softbreak
        case linebreak
        case code
        case emph
        case strong
        case link
        case image
        case html_inline
    }
    
    class Node {
        var type: NodeType
        var start: Int
        var end: Int
        var parent: Node?
        var children: [Node]?
        var contents: String?
        var attributes: [String:String]?
        
        init(type: NodeType) {
            self.type = type
            start = 0
            end = 0
            parent = nil
            children = nil
            contents = nil
            attributes = nil
        }
    }
    
    func getNodes() -> Node {
        let blocks = getBlocks()
        return _getNodes(blocks)
    }

    // MARK: HTML
    func getHtml() -> String {
        let document = getNodes()
        return _getHtml(document)
    }
    
    // MARK: DebugInfo
    func getDebugInfo() -> String {
        return _getDebugInfo()
    }
    
    // MARK: - Private -
    
    // MARK: Line
    private func _getLines(_ str: String) -> [Line] {
        // Get lines from a string.
        var lines = [Line]()
        var index = str.startIndex
        var start = index
        
        while index < str.endIndex {
            if str[index] == "\n" || str[index] == "\r" || str[index] == "\r\n" {
                let line = Line(start: start, end: index)
                lines.append(line)
                start = str.index(after: index)
            }
            index = str.index(after: index)
        }
        if start < str.endIndex {
            let end = str.index(before: str.endIndex)
            let line = Line(start: start, end: end)
            lines.append(line)
        }
        return lines
    }
    
    private func lineString(_ str: String) -> String {
        var output = ""
        for i in 0..<str.count {
            let ch = str[str.index(str.startIndex, offsetBy: i)]
            switch ch {
            case "\n":
                output += "[\\n]"
            case "\r":
                output += "[\\r]"
            case "\r\n":
                output += "[\\r\\n]"
            default:
                output += "[\(ch)]"
            }
        }
        return output
    }

    // MARK: Block
    private let blockRules = [
        (#"^ {0,3}- .*$"#, BlockType.list_item),
        (#"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, BlockType.setext_heading),
        (#"^{0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^{1,}\t((\*[ \t]*){3,}|(-[ \t]*){3,}|(_[ \t]*){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^ {0,3}#{1,6}[ \t].*$"#, BlockType.atx_heading),
        (#"^ {0,3}#{1,6}$"#, BlockType.atx_heading),
        (#"^ {0,3}>[ \t].*$"#, BlockType.block_quote),
        (#"^( {4,}).*$"#, BlockType.indented_code_block),
        (#"^ *\t{1,}.*$"#, BlockType.indented_code_block),
        (#"^ {0,3}```.*$"#, BlockType.fenced_code_block),
        (#"^ {0,3}~~~.*$"#, BlockType.fenced_code_block),
        (#"^<.*"#, BlockType.html_block),
        (#"^[\n\r]"#, BlockType.blank_line),
        (#".*"#, BlockType.paragraph)
    ]

    private func _getBlocks(_ lines: [Line]) -> [Block] {
        var blocks = [Block]()
        var lineNumber = 0
        while lineNumber < lines.count {
            let line = lines[lineNumber]
            let lineStr = source[line.start...line.end]
            for (rule, blockType) in blockRules {
                if lineStr.range(of: rule, options: .regularExpression) != nil {
                    // Recognized line.
                    switch blockType {
                    case .setext_heading:
                        if let previousBlock = getLastBlock(blocks, ifType: .paragraph) {
                            // Setext_heading
                            previousBlock.end = line.end
                            previousBlock.type = .setext_heading
                        } else {
                            continue
                        }
                    case .fenced_code_block:
                        if lineNumber + 1 < lines.count {
                            var nextLine = lines[lineNumber + 1]
                            var nextLineStr = source[nextLine.start...nextLine.end]
                            while (lineNumber + 1 < lines.count) && nextLineStr.range(of: #"^ {0,3}```.*$"#, options: .regularExpression) == nil && nextLineStr.range(of: #"^ {0,3}~~~.*$"#, options: .regularExpression) == nil  {
                                lineNumber = lineNumber + 1
                                if lineNumber + 1 < lines.count {
                                    nextLine = lines[lineNumber + 1]
                                    nextLineStr = source[nextLine.start...nextLine.end]
                                }
                            }
                            if lineNumber + 1 < lines.count {
                                lineNumber = lineNumber + 1
                            }
                            let block = Block(start: line.start, end: nextLine.end, type: .fenced_code_block)
                            blocks.append(block)
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .html_block:
                        if lineNumber + 1 < lines.count {
                            var nextLine = lines[lineNumber + 1]
                            var nextLineStr = source[nextLine.start...nextLine.end]
                            while (lineNumber + 1 < lines.count) && nextLineStr.range(of: #"^</.*$"#, options: .regularExpression) == nil  {
                                lineNumber = lineNumber + 1
                                if lineNumber + 1 < lines.count {
                                    nextLine = lines[lineNumber + 1]
                                    nextLineStr = source[nextLine.start...nextLine.end]
                                }
                            }
                            if lineNumber + 1 < lines.count {
                                lineNumber = lineNumber + 1
                            }
                            let block = Block(start: line.start, end: nextLine.end, type: .html_block)
                            blocks.append(block)
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .indented_code_block:
                        if let previousBlock = getLastBlock(blocks, ifType: blockType) {
                            // Continue
                            previousBlock.end = line.end
                        } else if let previousBlock = getLastBlock(blocks, ifType: .paragraph) {
                            // Continue
                            previousBlock.end = line.end
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .paragraph,
                         .blank_line,
                         .list_item,
                         .block_quote:
                        if let previousBlock = getLastBlock(blocks, ifType: blockType) {
                            // Continue
                            previousBlock.end = line.end
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    default:
                        let block = Block(start: line.start, end: line.end, type: blockType)
                        blocks.append(block)
                    }
                    break
                }
            }
            lineNumber = lineNumber + 1
        }
        return blocks
    }
    
    private func getLastBlock(_ blocks: [Block], ifType type: BlockType) -> Block? {
        // Get last block if of a specific type
        if let block = blocks.last {
            if block.type == type {
                return block
            }
        }
        return nil
    }
    
    private func blockTypeString(_ block: Markdown.Block) -> String {
        switch block.type {
        case .atx_heading:
            return "<ATX_HEADING>"
        case .setext_heading:
            return "<SETEXT_HEADING>"
        case .paragraph:
            return "<PARAGRAPH>"
        case .thematic_break:
            return "<THEMATIC_BREAK>"
        case .list_item:
            return "<LIST_ITEM>"
        case .blank_line:
            return "<BLANK_LINE>"
        default:
            return "<Unknown>"
        }
    }

    // MARK: HTML
    private func _getHtml(_ node: Node) -> String {
        var html = ""
        switch node.type {
        case .document:
            if let children = node.children {
                for node in children {
                    html += _getHtml(node)
                }
            }
        case .block_quote:
            break
        case .list:
            break
        case .item:
            break
        case .code_block:
            break
        case .paragraph:
            break
        case .heading:
            break
        case .thematic_break:
            html += "<hr />\n"
        case .html_block:
            break
        case .text:
            break
        case .softbreak:
            break
        case .linebreak:
            break
        case .code:
            break
        case .emph:
            break
        case .strong:
            break
        case .link:
            break
        case .image:
            break
        case .html_inline:
            break
        }
        return html
    }
    
    private func _getHtml() -> String {
        var html = ""
        let blocks = getBlocks()
        for i in 0..<blocks.count {
            var blockContents = ""
            var index = blocks[i].start
            while index <= blocks[i].end {
                if source[index] == "\0" {
                    blockContents += "\u{FFFD}"
                }
                else if source[index].isNewline {
                    // Trim whitespace
                    blockContents = blockContents.trimmingCharacters(in: .whitespaces)
                    blockContents += "\n"
                    index = source.index(after: index)
                    while index <= blocks[i].end && source[index].isWhitespace {
                        index = source.index(after: index)
                    }
                    index = source.index(before: index)
                }
                else {
                    blockContents += source[index...index]
                }
                index = source.index(after: index)
            }
            // Trim final newline
            if blockContents.count > 0 {
                let lastChar = blockContents.index(before: blockContents.endIndex)
                if blockContents[lastChar...lastChar] == "\n" {
                    blockContents = String(blockContents[blockContents.startIndex..<lastChar])
                }
            }
            // Trim final whitespace
            blockContents = blockContents.trimmingCharacters(in: .whitespaces)
            switch blocks[i].type {
            case .thematic_break:
                html += "<hr />\n"
            case .atx_heading:
                var level = 0
                var start = blockContents.startIndex
                while blockContents.index(start, offsetBy: level) < blockContents.endIndex && blockContents[blockContents.index(start, offsetBy: level)] == "#" {
                    level = level + 1
                }
                if blockContents.index(start, offsetBy: level) < blockContents.endIndex {
                    // Trim final #-characters
                    start = blockContents.index(start, offsetBy: level)
                    var lastChar = blockContents.index(before: blockContents.endIndex)
                    while lastChar > start && blockContents[lastChar...lastChar] == "#" {
                        blockContents = String(blockContents[blockContents.startIndex..<lastChar])
                        lastChar = blockContents.index(before: blockContents.endIndex)
                    }
                    start = blockContents.index(after: start)
                    blockContents = String(blockContents[start..<blockContents.endIndex])
                } else {
                    blockContents = ""
                }
                html += "<h\(level)>\(blockContents)</h\(level)>\n"
            case .setext_heading:
                let lines = _getLines(blockContents)
                let setext_indicator = blockContents[lines[lines.count - 1].start]
                if setext_indicator == "=" {
                    html += "<h1>"
                } else {
                    html += "<h2>"
                }
                for i in 0...lines.count - 2 {
                    html += blockContents[lines[i].start...lines[i].end]
                }
                // trim last newline
                let lastChar = html.index(before: html.endIndex)
                if html[lastChar...lastChar] == "\n" {
                    html = String(html[html.startIndex..<lastChar])
                }
                if setext_indicator == "=" {
                    html += "</h1>\n"
                } else {
                    html += "</h2>\n"
                }
            case .indented_code_block:
                html += "<pre><code>\(blockContents)\n</code></pre>\n"
            case .fenced_code_block:
                html += "<pre><code>"
                let lines = _getLines(blockContents)
                if lines.count > 2 {
                    for i in 1...lines.count - 2 {
                        html += blockContents[lines[i].start...lines[i].end]
                    }
                    // trim last newline
                    let lastChar = html.index(before: html.endIndex)
                    if html[lastChar...lastChar] == "\n" {
                        html = String(html[html.startIndex..<lastChar])
                    }
                }
                html += "</code></pre>\n"
            case .paragraph:
                html += "<p>\(blockContents)</p>\n"
            case .html_block:
                html += "\(blockContents)\n"
            case .block_quote:
                let lines = _getLines(blockContents)
                html += "<blockquote>"
                for line in lines {
                    if blockContents.count > 1 {
                        if blockContents[line.start...line.end].count > 2 {
                            let start = blockContents.index(after: line.start)
                            var lineStr = String(blockContents[start...line.end])
                            lineStr = lineStr.trimmingCharacters(in: .whitespacesAndNewlines)
                            html += "\(lineStr)\n"
                        }
                    }
                }
                html += "</blockquote>\n"
            case .list_item:
                let lines = _getLines(blockContents)
                html += "<ul>\n"
                for line in lines {
                    if blockContents.count > 1 {
                        let start = blockContents.index(after: line.start)
                        if start < line.end {
                            var lineStr = String(blockContents[start...line.end])
                            lineStr = lineStr.trimmingCharacters(in: .whitespacesAndNewlines)
                            html += "<li>\(lineStr)</li>\n"
                        } else {
                            html += "<li></li>\n"
                        }
                    } else {
                        html += "<li></li>\n"
                    }
                }
                html += "</ul>\n"
            case .blank_line:
                break
            default:
                html += "<div class=\"unknown\">\(blockContents)</div>\n"
            }
        }
        return html
    }
    
    // MARK: Node
    private enum Rule {
        case list
        case setext_heading
        case thematic_break
        case atx_heading
        case block_quote
        case indented_code_block
        case fenced_code_block
        case html_block
        case blank_line
        case paragraph
    }
    
    private let rules = [
        (#"^ {0,3}- .*$"#, Rule.list),
        (#"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, Rule.setext_heading),
        (#"^{0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, Rule.thematic_break),
        (#"^{1,}\t((\*[ \t]*){3,}|(-[ \t]*){3,}|(_[ \t]*){3,})[ \t]*$"#, Rule.thematic_break),
        (#"^ {0,3}#{1,6}[ \t].*$"#, Rule.atx_heading),
        (#"^ {0,3}#{1,6}$"#, Rule.atx_heading),
        (#"^ {0,3}>[ \t].*$"#, Rule.block_quote),
        (#"^( {4,}).*$"#, Rule.indented_code_block),
        (#"^ *\t{1,}.*$"#, Rule.indented_code_block),
        (#"^ {0,3}```.*$"#, Rule.fenced_code_block),
        (#"^ {0,3}~~~.*$"#, Rule.fenced_code_block),
        (#"^<.*"#, Rule.html_block),
        (#"^[\n\r]"#, Rule.blank_line),
        (#".*"#, Rule.paragraph)
    ]

    private func _getNodes(_ blocks: [Block]) -> Node {
        // Initialize the document node
        let document = Node(type: .document)
        document.start = source.getPosition(source.startIndex)
        document.end = source.getPosition(source.index(before: source.endIndex))
        document.children = [Node]()
        
        let blocks = getBlocks()
        for i in 0..<blocks.count {
            switch blocks[i].type {
            case .thematic_break:
                let node = thematicBreakNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .atx_heading:
                break
            case .setext_heading:
                break
            case .indented_code_block:
                break
            case .fenced_code_block:
                break
            case .html_block:
                break
            case .link_reference_definition:
                break
            case .paragraph:
                break
            case .block_quote:
                break
            case .list_item:
                break
            case .blank_line:
                break
            }
        }
        return document
    }
    
    func thematicBreakNode(_ block: Block) -> Node {
        let node = Node(type: .thematic_break)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        return node
    }
    
    private func getLastNode(_ nodes: [Node], ifType type: NodeType) -> Node? {
        // Return the last node if of a specific type
        if let node = nodes.last {
            if node.type == type {
                return node
            }
        }
        return nil
    }
    
    // MARK: Debug
    func _getDebugInfo() -> String {
        var debugInfo = ""
        
        let lines = getLines()
        debugInfo += "Source size: \(source.count)\n"
        debugInfo += "Number of lines: \(lines.count)\n"
        for i in 0..<lines.count {
            let line = String(source[lines[i].start...lines[i].end])
            debugInfo += "Line \(i) (length \(line.count)):\t\(lineString(line))\n"
        }
        
        let blocks = getBlocks()
        debugInfo += "Number of Blocks: \(blocks.count)\n"
        for i in 0..<blocks.count {
            let block = String(source[blocks[i].start...blocks[i].end])
            debugInfo += "Block \(i) (length: \(block.count)): Type: \(blockTypeString(blocks[i]))\n"
            debugInfo += "\(lineString(block))\n"
        }
        
        return debugInfo
    }
}

extension String {
    // Helper function to get the Integer position of a String.Index position
    func getPosition(_ pos: String.Index) -> Int {
        let position = self.distance(from: self.startIndex, to: pos)
        return position
    }
    // Helper function to get the String.Index position from an Integer position.
    func getIndex(_ pos: Int) -> String.Index {
        let index = self.index(startIndex, offsetBy: pos)
        return index
    }
}
