//
//  DebugView.swift
//  MarkdownEditor
//
//  Created by Patrick Van den Bergh on 08/04/2021.
//

import SwiftUI

struct DebugView: View {
    var text: String
    var body: some View {
        ScrollView {
            VStack {
                Text(debugText())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(Font.custom("Courier", size: 14.0))
                Spacer()
            }
        }
        .background(Color.white)
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
    
    func blockTypeString(_ block: Block) -> String {
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
    
    func debugText() -> String {
        var debugText = ""
        let scanner = Scanner(source: text)
        let lines = scanner.getLines()
        debugText += "Source size: \(text.count)\n"
        debugText += "Number of lines: \(lines.count)\n"
        for i in 0..<lines.count {
            let line = String(scanner.source[lines[i].start...lines[i].end])
            debugText += "Line \(i) (lengte \(line.count)):\t\(lineString(line))\n"
        }
        let blocks = scanner.getBlocks()
        debugText += "Number of Blocks: \(blocks.count)\n"
        for i in 0..<blocks.count {
            let block = String(scanner.source[blocks[i].start...blocks[i].end])
            debugText += "Block \(i) (lengte: \(block.count)): Type: \(blockTypeString(blocks[i]))\n"
            debugText += "\(lineString(block))\n"
        }

        return debugText
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView(text: "Test")
    }
}
