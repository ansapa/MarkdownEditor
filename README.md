# MarkdownEditor

MarkdownEditor is an experiment to create an editor with syntax highlighting for Markdown. It includes my own Markdown parser, which tries to be Commonmark compliant (currently only 23% of the test cases pass).

<img width="100%" alt="Screenshot" src="https://user-images.githubusercontent.com/50514472/114135827-1b334680-990a-11eb-81b0-4776f389c682.png">

Currently supported:

Thematic breaks:
***
---
___

ATX Headings:
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
####### No Heading 7 (as expected)

Setext Headings:

Heading Level 1
===============

Heading Level 2
---------------

Intended code blocks:

    Intended code blocks (with tabs)
    (or with minimal four spaces)

Fenced code blocks:
```
Fenced code block
```

Paragraphs:

(What is not recognized becomes a praragraph.)

Block quotes:
> This is a block quote.

List items:
- Item 1
- Item 2
- Item 3
