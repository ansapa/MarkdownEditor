//
//  MarkdownEditorTests.swift
//  MarkdownEditorTests
//
//  Created by Patrick Van den Bergh on 09/04/2021.
//

import XCTest

class MarkdownEditorTests: XCTestCase {
    // Test cases are stored in Tests.json.
    // This file is build on the CommonMark Spec v0.29 (2019-04-06)
    // see https://spec.commonmark.org/0.29/

    struct Test: Decodable {
        let markdown: String
        let html: String
        let example: Int
        let start_line: Int
        let end_line: Int
        let section: String
    }
    
    struct Score {
        var success: Int
        var total: Int
    }

    var tests = [Test]()
    var score = Score(success: 0, total: 0)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        var contents = ""
        let bundle = Bundle(for: type(of: self))
        if let filepath = bundle.path(forResource: "Tests", ofType: "json") {
            do {
                contents = try String(contentsOfFile: filepath)
            } catch {
                fatalError("Can not read info.plist")
            }
        }
        let jsonData = contents.data(using: .utf8)!
        tests = try! JSONDecoder().decode([Test].self, from: jsonData)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCommonMarkSpec() throws {
        for test in tests {
            print("============")
            print("testCase \(test.example)")
            print("============")
            print("Section: \(test.section)\n")
            let markdown = test.markdown
            print("Markdown:\n\(markdown)")
            let html = test.html
            print("Expected HTML:\n\(html)")
            let generatedHtml = Markdown(markdown).getHtml()
            print("Generated HTML:\n\(generatedHtml)")
            if generatedHtml ==  html {
                score.success += 1
            }
            score.total += 1
            XCTAssertTrue(generatedHtml == html)
        }
        print("+=======+")
        print("| Score |")
        print("+=======+")
        print()
        print("\(score.success) / \(score.total)")
        print()
        print()
    }
}
