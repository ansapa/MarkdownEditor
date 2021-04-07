//
//  Block.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import Foundation

enum BlockType {
    case thematic_break
    case atx_heading
    case setext_heading
    case indented_code_block
    case fenced_code_block
    case html_block
    case paragraph
    case line
    case block_quote
    case blank_line
}

struct Block {
    var start: String.Index
    var end: String.Index
    var type: BlockType
}
