//
//  Scanner.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import Foundation

class Scanner {
    let source: String
    
    init(source: String) {
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
                    switch (blockType) {
                    case .paragraph:
                        if lineNumber + 1 < lines.count {
                            // Check for Setext heading
                            let nextLine = lines[lineNumber + 1]
                            let nextLineStr = source[nextLine.start...nextLine.end]
                            if nextLineStr.range(of: #"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, options: .regularExpression) != nil {
                                // Setext Heading
                                lineNumber = lineNumber + 1
                                let block = Block(start: line.start, end: nextLine.end, type: .setext_heading)
                                blocks.append(block)
                            } else {
                                let block = Block(start: line.start, end: line.end, type: blockType)
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
}
