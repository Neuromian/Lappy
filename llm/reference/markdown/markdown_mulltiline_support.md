https://medium.com/@amazing_gs/flutter-markdown-using-markdown-with-cross-line-selection-in-flutter-0660dc34ec27

How to enable multi-line selection:
To solve the issue of multi-line selection, we can use the flutter_markdown_selectionarea package.

To use it just replace flutter_markdown dependency in your pubspec.yaml with

flutter_markdown_selectionarea: ^0.6.17+1
and then change all imports from

import 'package:flutter_markdown/flutter_markdown.dart';
to

import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
and then you will be able to make multiple paragraphs selectable by using SelectionArea widget:

SelectionArea(
  child: MarkdownBody(data: text),
Here is the modified code:

body: Center(
          child: SelectionArea( // new
            child: Markdown(
              // selectable: true, // remove
              data: markdown,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 24, color: Colors.blue),
                code: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    backgroundColor: Colors.grey),
                codeblockPadding: const EdgeInsets.all(8),
                codeblockDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ));
Now, multi-line selection is supported.

