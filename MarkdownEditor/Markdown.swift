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
        case unordered_list
        case ordered_list
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
        case unorderedList
        case orderedList
        case unorderedItem
        case orderedItem
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
        (#"^ {0,3}((=){1,}|(-){1,})[ \t]*$"#, BlockType.setext_heading),
        (#"^ {0,3}((\* *){3,}|(- *){3,}|(_ *){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^ {1,}\t((\*[ \t]*){3,}|(-[ \t]*){3,}|(_[ \t]*){3,})[ \t]*$"#, BlockType.thematic_break),
        (#"^ {0,3}- .*$"#, BlockType.unordered_list),
        (#"^ {0,3}[0-9]*[\.)] .*$"#, BlockType.ordered_list),
        (#"^ {0,3}#{1,6}[ \t].*$"#, BlockType.atx_heading),
        (#"^ {0,3}#{1,6}$"#, BlockType.atx_heading),
        (#"^ {0,3}>.*$"#, BlockType.block_quote),
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
                        } else if let previousBlock = getLastBlock(blocks, ifType: .unordered_list) {
                            // Continue
                            previousBlock.end = line.end
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .blank_line:
                        if let previousBlock = getLastBlock(blocks, ifType: blockType) {
                            // Continue
                            previousBlock.end = line.end
                        } else if let previousBlock = getLastBlock(blocks, ifType: .unordered_list) {
                            // Continue
                            previousBlock.end = line.end
                        }
                        else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .paragraph:
                        if let previousBlock = getLastBlock(blocks, ifType: blockType) {
                            // Continue
                            previousBlock.end = line.end
                        } else if let previousBlock = getLastBlock(blocks, ifType: .block_quote) {
                            // Coninue
                            previousBlock.end = line.end
                        } else if let previousBlock = getLastBlock(blocks, ifType: .unordered_list) {
                            // Coninue
                            previousBlock.end = line.end
                        } else {
                            let block = Block(start: line.start, end: line.end, type: blockType)
                            blocks.append(block)
                        }
                    case .unordered_list,
                         .ordered_list,
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
        
    private func blockTypeString(_ block: Block) -> String {
        switch block.type {
        case .block_quote:
            return "<BLOCK_QUOTE>"
        case .atx_heading:
            return "<ATX_HEADING>"
        case .setext_heading:
            return "<SETEXT_HEADING>"
        case .paragraph:
            return "<PARAGRAPH>"
        case .thematic_break:
            return "<THEMATIC_BREAK>"
        case .unordered_list:
            return "<LIST_ITEM>"
        case .blank_line:
            return "<BLANK_LINE>"
        default:
            return "<Unknown>"
        }
    }
    
    private func blockContents(_ block: Block) -> String {
        var blockContents = ""
        var index = block.start
        while index <= block.end {
            if source[index] == "\0" {
                blockContents += "\u{FFFD}"
            }
            else if source[index].isNewline {
                // Trim whitespace
                blockContents = blockContents.trimmingCharacters(in: .whitespaces)
                blockContents += "\n"
                index = source.index(after: index)
                while index <= block.end && source[index].isWhitespace {
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

        return blockContents
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
        if blocks.count > 0 {
            document.start = source.getPosition(source.startIndex)
            document.start = source.getPosition(source.index(before: source.endIndex))
        } else {
            document.start = 0
            document.end = 0
        }
        document.children = [Node]()
        
        for i in 0..<blocks.count {
            switch blocks[i].type {
            case .thematic_break:
                let node = thematicBreakNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .atx_heading:
                let node = atxHeadingNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .setext_heading:
                let node = setextHeadingNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .indented_code_block:
                let node = indentedCodeBlockNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .fenced_code_block:
                let node = fencedCodeBlockNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .html_block:
                let node = htmlBlockNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .link_reference_definition:
                let node = linkReferenceNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .paragraph:
                let node = paragraphNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .block_quote:
                let node = blockQuoteNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .unordered_list:
                let node = unorderedListNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .ordered_list:
                let node = orderedListNode(blocks[i])
                node.parent = document
                document.children?.append(node)
            case .blank_line:
                break
            }
        }
        return document
    }
    
    func thematicBreakNode(_ block: Block) -> Node {
        guard block.type == .thematic_break else {
            fatalError("thematicBreakNode: invalid block type")
        }
        let node = Node(type: .thematic_break)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        return node
    }

    func atxHeadingNode(_ block: Block) -> Node {
        guard block.type == .atx_heading else {
            fatalError("atxHeadingNode: invalid block type")
        }
        let node = Node(type: .heading)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        let contents = blockContents(block)
        var level = 0
        let start = contents.startIndex
        while contents.index(start, offsetBy: level) < contents.endIndex && contents[contents.index(start, offsetBy: level)] == "#" {
            level = level + 1
        }
        node.attributes = ["Level":"\(level)"]
        let trimCharacterSet = CharacterSet(charactersIn: "\t \n#")
        let trimmedContents = contents.trimmingCharacters(in: trimCharacterSet)
        let contentTokens = getTokens(trimmedContents)
        node.children = getInlineNodes(tokens: contentTokens)
        return node
    }

    func setextHeadingNode(_ block: Block) -> Node {
        guard block.type == .setext_heading else {
            fatalError("setextHeadingNode: invalid block type")
        }
        let node = Node(type: .heading)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        let contents = blockContents(block)
        let lines = _getLines(contents)
        let setext_indicator = contents[lines[lines.count - 1].start]
        if setext_indicator == "=" {
            node.attributes = ["Level":"1"]
        } else {
            node.attributes = ["Level":"2"]
        }
        var nodeContents = ""
        for i in 0...lines.count - 2 {
            nodeContents += contents[lines[i].start...lines[i].end]
        }
        // Trim last spaces/newlines
        nodeContents = nodeContents.trimmingCharacters(in: .whitespacesAndNewlines)
        let contentTokens = getTokens(nodeContents)
        node.children = getInlineNodes(tokens: contentTokens)
        return node
    }

    func indentedCodeBlockNode(_ block: Block) -> Node {
        guard block.type == .indented_code_block else {
            fatalError("indentedCodeBlockNode: invalid block type")
        }
        let node = Node(type: .code_block)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        node.contents = blockContents(block).trimmingCharacters(in: .whitespacesAndNewlines)
        return node
    }
    
    func fencedCodeBlockNode(_ block: Block) -> Node {
        guard block.type == .fenced_code_block else {
            fatalError("fencedCodeBlockNode: invalid block type")
        }
        let node = Node(type: .code_block)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        let contents = blockContents(block)
        let lines = _getLines(contents)
        node.contents = ""
        if lines.count > 2 {
            for i in 1...lines.count - 2 {
                node.contents! += contents[lines[i].start...lines[i].end]
            }
        }
        // Trim last spaces/newlines
        node.contents = node.contents?.trimmingCharacters(in: .whitespacesAndNewlines)
        return node
    }

    func htmlBlockNode(_ block: Block) -> Node {
        guard block.type == .html_block else {
            fatalError("htmlBlockNode: invalid block type")
        }
        let node = Node(type: .html_block)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        node.contents = blockContents(block)
        return node
    }

    func linkReferenceNode(_ block: Block) -> Node {
        guard block.type == .link_reference_definition else {
            fatalError("linkReferenceNode: invalid block type")
        }
        let node = Node(type: .link)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        return node
    }

    func paragraphNode(_ block: Block) -> Node {
        guard block.type == .paragraph else {
            fatalError("paragraphNode: invalid block type")
        }
        let node = Node(type: .paragraph)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        let contents = blockContents(block).trimmingCharacters(in: .whitespacesAndNewlines)
        let contentTokens = getTokens(contents)
        node.children = getInlineNodes(tokens: contentTokens)
        return node
    }

    func blockQuoteNode(_ block: Block) -> Node {
        guard block.type == .block_quote else {
            fatalError("blockQuoteNode: invalid block type")
        }
        let node = Node(type: .block_quote)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        node.children = [Node]()
        // Create a new string with lines stripped by Block quote symbol
        var quoteContents = ""
        let blockString = blockContents(block)
        let lines = _getLines(blockString)
        for line in lines {
            let lineString = String(blockString[line.start...line.end]).leftTrim([" ", "\t"])
            quoteContents += String(lineString[lineString.index(after: lineString.startIndex)..<lineString.endIndex])
        }
        // Build nodes from this
        let markdown = Markdown(quoteContents)
        let document = markdown.getNodes()
        // Add nodes as children
        if let nodeList = document.children {
            for n in nodeList {
                node.children?.append(n)
            }
        }
        return node
    }

    func unorderedListNode(_ block: Block) -> Node {
        guard block.type == .unordered_list else {
            fatalError("listItemNode: invalid block type")
        }
        let node = Node(type: .unorderedList)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        node.children = [Node]()
        node.attributes = ["Tight":"true"]
        let lines = _getLines(String(source[block.start...block.end]))
        var listItemString = ""
        var listItemStart = source.getPosition(block.start)
        var listItemEnd = source.getPosition(block.end)
        for line in lines {
            let lineStr = String(source[line.start...line.end])
            if lineStr.range(of: #"^ {0,3}- .*$"#, options: .regularExpression) != nil {
                if listItemString.count > 0 {
                    let itemNode = makeUnorderedItem(contents: listItemString, start: listItemStart, end: listItemEnd)
                    node.children?.append(itemNode)
                    if let tight = itemNode.attributes?["Tight"] {
                        if tight == "false" {
                            node.attributes = itemNode.attributes
                            for child in node.children! {
                                child.attributes = node.attributes
                            }
                        } else {
                            itemNode.attributes = node.attributes
                        }
                    } else {
                        itemNode.attributes = node.attributes
                    }
                }
                listItemString = lineStr
                listItemStart = source.getPosition(line.start)
                listItemEnd = source.getPosition(line.end)
            } else {
                listItemString += lineStr
                listItemEnd = source.getPosition(line.end)
            }
        }
        if listItemString.count > 0 {
            let itemNode = makeUnorderedItem(contents: listItemString, start: listItemStart, end: listItemEnd)
            itemNode.attributes = node.attributes
            node.children?.append(itemNode)
        }
        return node
    }
    
    func orderedListNode(_ block: Block) -> Node {
        guard block.type == .ordered_list else {
            fatalError("orderedListNode: invalid block type")
        }
        let node = Node(type: .orderedList)
        node.start = source.getPosition(block.start)
        node.end = source.getPosition(block.end)
        node.children = [Node]()
        node.attributes = ["Tight":"true"]
        let blockString = String(source[block.start...block.end])
        let lines = _getLines(blockString)
        var listItemString = ""
        var listItemStart = source.getPosition(block.start)
        var listItemEnd = source.getPosition(block.end)
        for line in lines {
            let lineStr = String(blockString[line.start...line.end])
            if lineStr.range(of: #"^ {0,3}[0-9]*[\.)] .*$"#, options: .regularExpression) != nil {
                if listItemString.count > 0 {
                    let itemNode = makeOrderedItem(contents: listItemString, start: listItemStart, end: listItemEnd)
                    node.children?.append(itemNode)
                    if let tight = itemNode.attributes?["Tight"] {
                        if tight == "false" {
                            node.attributes = itemNode.attributes
                            for child in node.children! {
                                child.attributes = node.attributes
                            }
                        } else {
                            itemNode.attributes = node.attributes
                        }
                    } else {
                        itemNode.attributes = node.attributes
                    }
                }
                listItemString = lineStr
                listItemStart = source.getPosition(line.start)
                listItemEnd = source.getPosition(line.end)
            } else {
                listItemString += lineStr
                listItemEnd = source.getPosition(line.end)
            }
        }
        if listItemString.count > 0 {
            let itemNode = makeOrderedItem(contents: listItemString, start: listItemStart, end: listItemEnd)
            itemNode.attributes = node.attributes
            node.children?.append(itemNode)
        }
        return node
    }
    
    func makeUnorderedItem(contents: String, start: Int, end: Int) -> Node {
        let node = Node(type: .unorderedItem)
        node.start = start
        node.end = end
        node.children = [Node]()
        let lines = _getLines(contents)
        if lines.count > 1 {
            for line in lines {
                if contents[line.start] == "\n" {
                    // empty line
                    node.attributes = ["Tight":"false"]
                }
            }
            
            // Create a new string with lines stripped by Block quote symbol
            var itemContents = ""
            let firstLine = String(contents[lines[0].start...lines[0].end]).leftTrim(["-", " ", "\t"])
            itemContents += firstLine
            // Determine jump
            var ch = lines[0].start
            var jump = 0
            while ch <= lines[0].end && contents[ch] != "-" {
                ch = contents.index(after: ch)
                jump = jump + 1
            }
            if ch <= lines[0].end {
                jump = jump + 1
            }
            if lines.count > 1 {
                for i in 1..<lines.count {
                    let lineStr = contents[lines[i].start...lines[i].end]
                    if lineStr.count > jump {
                        itemContents += String(contents[contents.index(lines[i].start, offsetBy: jump)...lines[i].end])
                    } else {
                        itemContents += "\n"
                    }
                }
            }
            // Build nodes from this
            let markdown = Markdown(itemContents)
            let document = markdown.getNodes()
            // Add nodes as children
            if let nodeList = document.children {
                for n in nodeList {
                    node.children?.append(n)
                }
            }
        } else {
            let trimmedContents = String(contents.leftTrim(["-", " ", "\t"]))
            let text = makeTextNode(contents: trimmedContents, start: start, end: end)
            node.children?.append(text)
        }
        return node
    }

    func makeOrderedItem(contents: String, start: Int, end: Int) -> Node {
        let node = Node(type: .unorderedItem)
        node.start = start
        node.end = end
        node.children = [Node]()
        let lines = _getLines(contents)
        if lines.count > 1 {
            for line in lines {
                if contents[line.start] == "\n" {
                    // empty line
                    node.attributes = ["Tight":"false"]
                }
            }
            
            // Create a new string with lines stripped by Block quote symbol
            var itemContents = ""
            for line in lines {
                let lineString = String(contents[line.start...line.end]).leftTrim(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ")", " ", "\t"])
                itemContents += lineString
            }
            // Build nodes from this
            let markdown = Markdown(itemContents)
            let document = markdown.getNodes()
            // Add nodes as children
            if let nodeList = document.children {
                for n in nodeList {
                    node.children?.append(n)
                }
            }
        } else {
            let trimmedContents = String(contents.leftTrim(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ")", " ", "\t"]))
            let text = makeTextNode(contents: trimmedContents, start: start, end: end)
            node.children?.append(text)
        }
        return node
    }

    func makeTextNode(contents: String, start: Int, end: Int) -> Node {
        let node = Node(type: .text)
        let trimCharacterSet = CharacterSet(charactersIn: " \n>")
        node.start = start
        node.end = end
        node.contents = contents.trimmingCharacters(in: trimCharacterSet)
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
    
    // MARK: Inline Tokens
    private enum TokenType {
        case non_whitespace
        case whitespace
        case line_ending
        case star
        case double_star
        case underscore
        case double_underscore
    }
    
    private struct Token {
        var type: TokenType
        var start: String.Index
        var end: String.Index
        var value: String
    }

    private func getTokens(_ str: String) -> [Token] {
        var tokens = [Token]()

        var i = str.startIndex
        
        while i < str.endIndex {
            if str[i].isWhitespace {
                var token = Token(type: .whitespace, start: i, end: i, value: "")
                var next = str.index(after: i)
                while next < str.endIndex && str[next].isWhitespace {
                    token.end = next
                    next = str.index(after: next)
                }
                token.value = String(str[token.start...token.end])
                tokens.append(token)
                i = str.index(after: token.end)
                continue
            }
            if str[i].isNewline {
                let token = Token(type: .line_ending, start: i, end: i, value: String(str[i]))
                tokens.append(token)
                i = str.index(after: token.end)
                continue
            }
            if str[i] == "*" {
                let next = str.index(after: i)
                let token: Token
                if next < str.endIndex && str[next] == "*" {
                    // Double star
                    token = Token(type: .double_star, start: i, end: next, value: "**")
                } else {
                    // Single star
                    token = Token(type: .star, start: i, end: i, value: String(str[i]))
                }
                tokens.append(token)
                i = str.index(after: token.end)
                continue
            }
            if str[i] == "_" {
                let next = str.index(after: i)
                let token: Token
                if next < str.endIndex && str[next] == "_" {
                    // Double underscore
                    token = Token(type: .double_underscore, start: i, end: next, value: "**")
                } else {
                    // Single underscore
                    token = Token(type: .underscore, start: i, end: i, value: String(str[i]))
                }
                tokens.append(token)
                i = str.index(after: token.end)
                continue
            }

            var token = Token(type: .non_whitespace, start: i, end: i, value: "")
            var next = str.index(after: i)
            while next < str.endIndex &&
                    !(str[next].isWhitespace ||
                      str[next].isNewline ||
                      str[next] == "*") {
                token.end = next
                next = str.index(after: next)
            }
            token.value = String(str[token.start...token.end])
            tokens.append(token)
            i = str.index(after: token.end)
        }
        
        return tokens
    }
    
    private func getInlineNodes(tokens: [Token]) -> [Node] {
        var nodes = [Node]()
        var i = 0
        var emph = false
        var strong = false
        var currentNode = Node(type: .text)
        currentNode.contents = ""
        while i < tokens.count {
            switch tokens[i].type {
            case .whitespace:
                currentNode.contents?.append(tokens[i].value)
            case .non_whitespace:
                currentNode.contents?.append(tokens[i].value)
            case .star:
                if !emph {
                    nodes.append(currentNode)
                    let emphNode = Node(type: .emph)
                    currentNode = Node(type: .text)
                    currentNode.contents = "*"
                    emphNode.children = [currentNode]
                    nodes.append(emphNode)
                    emph = true
                } else {
                    currentNode.contents = currentNode.contents?.leftTrim(["*"])
                    currentNode = Node(type: .text)
                    currentNode.contents = ""
                    emph = false
                }
            case .underscore:
                if !emph {
                    nodes.append(currentNode)
                    let emphNode = Node(type: .emph)
                    currentNode = Node(type: .text)
                    currentNode.contents = "*"
                    emphNode.children = [currentNode]
                    nodes.append(emphNode)
                    emph = true
                } else {
                    currentNode.contents = currentNode.contents?.leftTrim(["*"])
                    currentNode = Node(type: .text)
                    currentNode.contents = ""
                    emph = false
                }
            case .double_star:
                if !strong {
                    nodes.append(currentNode)
                    let emphNode = Node(type: .strong)
                    currentNode = Node(type: .text)
                    currentNode.contents = "**"
                    emphNode.children = [currentNode]
                    nodes.append(emphNode)
                    strong = true
                } else {
                    currentNode.contents = currentNode.contents?.leftTrim(["*"])
                    currentNode = Node(type: .text)
                    currentNode.contents = ""
                    strong = false
                }
            case .double_underscore:
                if !strong {
                    nodes.append(currentNode)
                    let emphNode = Node(type: .strong)
                    currentNode = Node(type: .text)
                    currentNode.contents = "**"
                    emphNode.children = [currentNode]
                    nodes.append(emphNode)
                    strong = true
                } else {
                    currentNode.contents = currentNode.contents?.leftTrim(["*"])
                    currentNode = Node(type: .text)
                    currentNode.contents = ""
                    strong = false
                }
            case .line_ending:
                break
            }
            i = i + 1
        }
        nodes.append(currentNode)
        return nodes
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
            html += "<blockquote>\n"
            if let children = node.children {
                for node in children {
                    html += _getHtml(node)
                }
            }
            html += "</blockquote>\n"
        case .unorderedList:
            html += "<ul>\n"
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            html += "</ul>\n"
        case .orderedList:
            html += "<ol>\n"
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            html += "</ol>\n"

        case .unorderedItem:
            html += "<li>"
            if let tight = node.attributes?["Tight"] {
                if tight == "false" {
                    html += "\n<p>"
                }
            }
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            if let tight = node.attributes?["Tight"] {
                if tight == "false" {
                    html += "</p>"
                }
            }
            html +=  "</li>\n"
        case .orderedItem:
            html += "<li>\n"
            if let tight = node.attributes?["Tight"] {
                if tight == "false" {
                    html += "<p>"
                }
            }
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            if let tight = node.attributes?["Tight"] {
                if tight == "false" {
                    html += "</p>"
                }
            }
            html +=  "</li>\n"
        case .code_block:
            html += "<pre><code>"
            if let contents = node.contents {
                html += contents.convertSpecialCharacters()
            }
            html +=  "\n</code></pre>\n"
        case .paragraph:
            html += "<p>"
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            html += "</p>\n"
        case .heading:
            if let level = node.attributes?["Level"] {
                html += "<h\(level)>"
            } else {
                html += "<h1>"
            }
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            if let level = node.attributes?["Level"] {
                html += "</h\(level)>\n"
            } else {
                html += "</h1>\n"
            }
        case .thematic_break:
            html += "<hr />\n"
        case .html_block:
            if let contents = node.contents {
                html += contents
            }
            html += "\n"
        case .text:
            if let contents = node.contents {
                html += contents.convertSpecialCharacters()
            }
        case .softbreak:
            break
        case .linebreak:
            html += "\n"
        case .code:
            break
        case .emph:
            html += "<em>"
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            html += "</em>"
        case .strong:
            html += "<strong>"
            if let children = node.children {
                for child in children {
                    html += _getHtml(child)
                }
            }
            html += "</strong>"
        case .link:
            break
        case .image:
            break
        case .html_inline:
            break
        }
        return html
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
    // Helper function to remove chars from the left.
    func leftTrim(_ chars: Set<Character>) -> String {
        if let index = self.firstIndex(where: {!chars.contains($0)}) {
            return String(self[index..<self.endIndex])
        } else {
            return ""
        }
    }
    // Helper function to conver special characters
    func convertSpecialCharacters() -> String {
        var newString = self
        let char_dictionary = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("\"", "&quot;)"),
            ("'", "&apos;")
        ];
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.literal, range: nil)
        }
        return newString
    }
}
