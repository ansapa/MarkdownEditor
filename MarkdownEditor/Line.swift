//
//  Line.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 05/04/2021.
//

import Foundation

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
