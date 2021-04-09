//
//  Markdown.swift
//  Markdown parser
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import Foundation

class Markdown {
    let source: String
    
    init(_ source: String) {
        self.source = source
    }
    
    func getLines() -> [Line] {
        var lines = [Line]()
        var index = source.startIndex
        var start = index
        
        while index < source.endIndex {
            if source[index] == "\n" || source[index] == "\r" || source [index] == "\r\n" {
                let lineStr = source[start...index]
                var hint = LineHint.unknown
                for (lineType, rule) in lineHintRules {
                    if lineStr.range(of: rule, options: .regularExpression) != nil {
                        hint = lineType
                    }
                }
                let line = Line(start: start, end: index, hint: hint)
                lines.append(line)
                start = source.index(after: index)
            }
            index = source.index(after: index)
        }
        if start < source.endIndex {
            let end = source.index(before: source.endIndex)
            let lineStr = source[start...end]
            var hint = LineHint.unknown
            for (lineType, rule) in lineHintRules {
                if lineStr.range(of: rule, options: .regularExpression) != nil {
                    hint = lineType
                }
            }
            let line = Line(start: start, end: end, hint: hint)
            lines.append(line)
        }
        return lines
    }

    let rules = [
        (#"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, BlockType.setext_heading),
        (#"^ {0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^ {0,3}#{1,6} .*$"#, BlockType.atx_heading),
        (#"^ {0,3}> .*$"#, BlockType.block_quote),
        (#"^ {4,}.*$"#, BlockType.indented_code_block),
        (#"^ {0,3}```.*$"#, BlockType.fenced_code_block),
        (#"^[\n\r]"#, BlockType.blank_line),
        (#".*"#, BlockType.paragraph)
    ]
    
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
    
    func getLast(_ blocks: [Block], ifType type: BlockType) -> Block? {
        if let block = blocks.last {
            if block.type == type {
                return block
            }
        }
        return nil
    }
    
    func getHtml() -> String {
        var html = ""
        let blocks = getBlocks()
        for i in 0..<blocks.count {
            var blockContents = ""
            var index = blocks[i].start
            while index <= blocks[i].end {
                if source[index] == "\0" {
                    blockContents += "\u{FFFD}"
                }
                else {
                    blockContents += source[index...index]
                }
                index = source.index(after: index)
            }
            // Trim whitespaces
            blockContents = blockContents.trimmingCharacters(in: .whitespaces)
            // Trim final newline
            let lastChar = blockContents.index(before: blockContents.endIndex)
            if blockContents[lastChar...lastChar] == "\n" {
                blockContents = String(blockContents[blockContents.startIndex..<lastChar])
            }
            switch blocks[i].type {
            case .thematic_break:
                html += "<hr />\n"
            case .atx_heading:
                var level = 0
                var start = blockContents.startIndex
                while blockContents[blockContents.index(start, offsetBy: level)] == "#" {
                    level = level + 1
                }
                start = blockContents.index(start, offsetBy: level+1)
                blockContents = String(blockContents[start..<blockContents.endIndex])
                html += "<h\(level)>\(blockContents)</h\(level)>\n"
            case .setext_heading:
                html += "<h1>\(blockContents)</h1>\n"
            case .indented_code_block:
                html += "<pre><code>\(blockContents)</code></pre>\n"
            case .fenced_code_block:
                html += "<code>\(blockContents)</code>\n"
            case .paragraph:
                html += "<p>\(blockContents)</p>\n"
            case .block_quote:
                html += "<cite>\(blockContents)</cite>\n"
            case .blank_line:
                break
            default:
                html += "<div class=\"unknown\">\(blockContents)</div>\n"
            }
        }
        return html
    }
    
    enum BlockType {
        case thematic_break
        case atx_heading
        case setext_heading
        case indented_code_block
        case fenced_code_block
        case html_block
        case paragraph
        case block_quote
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
    
    enum LineHint {
        case blank_line
        case setext_underline
        case thematic_break
        case atx_heading
        case indented_code
        case code_fence
        case html
        case link_label
        case block_quote
        case list_item
        case paragraph
        case unknown
    }

    let lineHintRules = [
        (LineHint.blank_line, #"^[\n\r]"#),
        (LineHint.setext_underline, #"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#),
        (LineHint.thematic_break, #"^ {0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#),
        (LineHint.atx_heading, #"^ {0,3}#{1,6} .*$"#),
        (LineHint.indented_code, #"^ {4,}.*$"#),
        (LineHint.code_fence, #"^ {0,3}[`~]{3}.*$"#),
    //    (LineHint.html, #""#),
    //    (LineHint.link_label, #""#),
        (LineHint.block_quote, #"^ {0,3}> .*$"#),
    //    (LineHint.list_item, #""#),
        (LineHint.paragraph, #".*"#)
    ]

    struct Line {
        let start: String.Index
        let end: String.Index
        let hint: LineHint
    }

}
