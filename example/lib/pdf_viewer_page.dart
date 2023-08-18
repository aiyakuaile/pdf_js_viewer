import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: FutureBuilder(
          future: rootBundle.load('assets/compressed.pdf'),
          builder: (BuildContext context, AsyncSnapshot<ByteData> snapshot){
        if(snapshot.hasData){
          return PDFViewerWidget.data(Uint8List.view(snapshot.data!.buffer));
        }else{
          return const Center(child: Text('加载中...'),);
        }
      }),
    );
  }
}
