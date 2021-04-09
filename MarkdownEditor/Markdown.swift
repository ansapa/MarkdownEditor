//
//  Markdown.swift
//  Markdown parser
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import Foundation

class Markdown {
    // MARK: - Public
    // These are the interfaces of the class
    let source: String
    
    init(_ source: String) {
        self.source = source
    }
    
    func getHtml() -> String {
        return _getHtml()
    }
    
    func getDebugInfo() -> String {
        return _getDebugInfo()
    }
    
    // MARK: - Private
    // This is internal stuff. User of the class should not worry about these.
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
                let lines = getLines(blockContents)
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
                let lines = getLines(blockContents)
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
            case .block_quote:
                let lines = getLines(blockContents)
                html += "<cite>"
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
                html += "</cite>\n"
            case .list_item:
                let lines = getLines(blockContents)
                html += "<ul>\n"
                for line in lines {
                    if blockContents.count > 1 {
                        let start = blockContents.index(after: line.start)
                        var lineStr = String(blockContents[start...line.end])
                        lineStr = lineStr.trimmingCharacters(in: .whitespacesAndNewlines)
                        html += "<li>\(lineStr)</li>\n"
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

    private func getLines(_ str: String) -> [Line] {
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

    func getLines() -> [Line] {
        var lines = [Line]()
        var index = source.startIndex
        var start = index
        
        while index < source.endIndex {
            if source[index] == "\n" || source[index] == "\r" || source[index] == "\r\n" {
                let line = Line(start: start, end: index)
                lines.append(line)
                start = source.index(after: index)
            }
            index = source.index(after: index)
        }
        if start < source.endIndex {
            let end = source.index(before: source.endIndex)
            let line = Line(start: start, end: end)
            lines.append(line)
        }
        return lines
    }

    func getBlocks() -> [Block] {
        var blocks = [Block]()
        let lines = getLines()
        var lineNumber = 0
        while lineNumber < lines.count {
            let line = lines[lineNumber]
            let lineStr = source[line.start...line.end]
            for (rule, blockType) in rules {
                if lineStr.range(of: rule, options: .regularExpression) != nil {
                    // Recognized line.
                    switch blockType {
                    case .setext_heading:
                        if let previousBlock = getLast(blocks, ifType: .paragraph) {
                            // Setext_heading
                            previousBlock.end = line.end
                            previousBlock.type = .setext_heading
                        } else {
                            if lineStr.range(of: #"^ {0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, options: .regularExpression) != nil {
                                let block = Block(start: line.start, end: line.end, type: .thematic_break)
                                blocks.append(block)
                            } else {
                                let block = Block(start: line.start, end: line.end, type: .paragraph)
                                blocks.append(block)
                            }
                        }
                    case .fenced_code_block:
                        if lineNumber + 1 < lines.count {
                            var nextLine = lines[lineNumber + 1]
                            var nextLineStr = source[nextLine.start...nextLine.end]
                            while lineNumber + 1 < lines.count && nextLineStr.range(of: #"^ {0,3}```.*$"#, options: .regularExpression) == nil {
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
                    case .indented_code_block:
                        if let previousBlock = getLast(blocks, ifType: blockType) {
                            // Continue
                            previousBlock.end = line.end
                        } else if let previousBlock = getLast(blocks, ifType: .paragraph) {
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
                        if let previousBlock = getLast(blocks, ifType: blockType) {
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
    
    private let rules = [
        (#"^- .*$"#, .list_item),
        (#"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, BlockType.setext_heading),
        (#"^ {0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^ {0,3}#{1,6}[ \t].*$"#, BlockType.atx_heading),
        (#"^ {0,3}#{1,6}$"#, BlockType.atx_heading),
        (#"^ {0,3}>[ \t].*$"#, BlockType.block_quote),
        (#"^( {4,}).*$"#, BlockType.indented_code_block),
        (#"^ *\t{1,}.*$"#, BlockType.indented_code_block),
        (#"^ {0,3}```.*$"#, BlockType.fenced_code_block),
        (#"^[\n\r]"#, BlockType.blank_line),
        (#".*"#, BlockType.paragraph)
    ]
    

    private func getLast(_ blocks: [Block], ifType type: BlockType) -> Block? {
        if let block = blocks.last {
            if block.type == type {
                return block
            }
        }
        return nil
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
    
    struct Line {
        let start: String.Index
        let end: String.Index
    }
  
    func lineString(_ str: String) -> String {
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
    
    func blockTypeString(_ block: Markdown.Block) -> String {
        switch block.type {
        case .atx_heading:
            return "<ATX_HEADING>"
        case .setext_heading:
            return "<SETEXT_HEADING>"
        case .paragraph:
            return "<PARAGRAPH>"
        case .thematic_break:
            return "<THEMATIC_BREAK>"
        case .blank_line:
            return "<BLANK_LINE>"
        default:
            return "<Unknown>"
        }
    }
    
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
