import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:jaguar/jaguar.dart';
import 'package:http/http.dart' as http;

class PDFViewerWidget extends StatefulWidget {
  /// support file path，http link
  final String? filePath;
  final Uint8List? fileData;
  final bool clearCache;
  const PDFViewerWidget({super.key, this.filePath,this.fileData,this.clearCache = false}):assert(filePath != null || fileData != null);

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();

  factory PDFViewerWidget.data(Uint8List data){
    return PDFViewerWidget(fileData:data);
  }

  factory PDFViewerWidget.network(String url){
    return PDFViewerWidget(filePath:url);
  }

  factory PDFViewerWidget.file(String absolutePath){
    return PDFViewerWidget(filePath:absolutePath);
  }
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  final server = Jaguar(port: 31211);
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  _loadPdfFile() async {
    await _controller.loadRequest(Uri.parse('http://127.0.0.1:31211/pdfjs/web/viewer.html?file=/api/intercept'));
  }

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  _startServer()async{
    server.addRoute(_serveFlutterAssets());
    server.get('/api/intercept', (Context ctx)async{
      List<int>? bytes;
      if(widget.fileData != null){
        log('Processing Uint8List data：：：：',name: 'pdf_js_viewer');
        bytes = widget.fileData!;
      }else if(widget.filePath!.startsWith('http')) {
        log('Processing Net data：：：：',name: 'pdf_js_viewer');
        final response = await http.get(Uri.parse(widget.filePath!));
        if(response.statusCode == 200){
          bytes = response.bodyBytes;
        }
      }else{
        log('Processing File data：：：：',name: 'pdf_js_viewer');
        bytes = await File(widget.filePath!).readAsBytes();
      }
      return ByteResponse(body: bytes, mimeType: 'application/pdf ');
    });
    await server.serve();
    _loadPdfFile();
  }

  Route _serveFlutterAssets(
      {String path = '*',
        bool stripPrefix = true,
        String prefix = '',
        Map<String, String>? pathRegEx,
        ResponseProcessor? responseProcessor}) {
    Route route;
    int skipCount = -1;
    route = Route.get(path, (ctx) async {
      Iterable<String> segs = ctx.pathSegments;
      if (skipCount > 0) segs = segs.skip(skipCount);

      String lookupPath =
          segs.join('/') + (ctx.path.endsWith('/') ? 'index.html' : '');
      final body = (await rootBundle.load('packages/pdf_js_viewer/assets/$prefix$lookupPath'))
          .buffer
          .asUint8List();

      String? mimeType;
      if (!ctx.path.endsWith('/')) {
        if (ctx.pathSegments.isNotEmpty) {
          final String last = ctx.pathSegments.last;
          if (last.contains('.')) {
            mimeType = MimeTypes.fromFileExtension[last.split('.').last];
          }
        }
      } else {
        mimeType = 'text/html';
      }

      ctx.response = ByteResponse(body: body, mimeType: mimeType);
    }, pathRegEx: pathRegEx, responseProcessor: responseProcessor);

    if (stripPrefix) skipCount = route.pathSegments.length - 1;

    return route;
  }

  @override
  void didUpdateWidget(covariant PDFViewerWidget oldWidget) {
    if(widget.filePath != oldWidget.filePath || widget.fileData != oldWidget.fileData){
      _controller.reload();
    }
    super.didUpdateWidget(oldWidget);
  }


  @override
  void dispose() {
    server.close();
    if(widget.clearCache){
      _controller.clearCache();
      _controller.clearLocalStorage();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
