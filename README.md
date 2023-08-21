## Features
**only support android and iOS**,
Based on the PDF file browser encapsulated in **pdf.js**, this plugin can help you find out how the PDF you are using cannot display relevant information such as signatures.

## Getting started

```dart
import 'package:pdf_js_viewer/pdf_js_viewer.dart';
```

## Usage

Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
import 'package:flutter/material.dart';
import 'package:pdf_js_viewer/pdf_js_viewer.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Detail'),),
      // body: PDFViewerWidget(fileData: data),
      // body: PDFViewerWidget(filePath: path),
      // body: PDFViewerWidget.data(data),
      // body: PDFViewerWidget.file(path),
    );
  }
}

```
