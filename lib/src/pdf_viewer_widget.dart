import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:jaguar/jaguar.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef PDFViewerControllerCallback<T> = void Function(T controller);

class PDFViewerWidget extends StatefulWidget {
  final PDFViewerControllerCallback<PDFViewerController>? onControllerCreated;

  /// support assets path, file path，http link
  final String? filePath;

  /// isAssets default false
  /// isAssets is true,filePath != null
  /// use rootBundle.load(widget.filePath!)
  final bool isAssets;
  final Uint8List? fileData;

  /// exit page to clear webView cache,default true
  final bool clearCache;

  const PDFViewerWidget._({super.key, this.onControllerCreated, this.filePath, this.fileData, this.isAssets = false, this.clearCache = true})
      : assert(filePath != null || fileData != null);

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();

  factory PDFViewerWidget.data(Uint8List data, {PDFViewerControllerCallback<PDFViewerController>? onControllerCreated, bool clearCache = true}) {
    return PDFViewerWidget._(
      fileData: data,
      clearCache: clearCache,
      onControllerCreated: onControllerCreated,
    );
  }

  factory PDFViewerWidget.network(String url, {PDFViewerControllerCallback<PDFViewerController>? onControllerCreated, bool clearCache = true}) {
    return PDFViewerWidget._(
      filePath: url,
      clearCache: clearCache,
      onControllerCreated: onControllerCreated,
    );
  }

  factory PDFViewerWidget.file(String absolutePath, {PDFViewerControllerCallback<PDFViewerController>? onControllerCreated, bool clearCache = true}) {
    return PDFViewerWidget._(
      filePath: absolutePath,
      clearCache: clearCache,
      onControllerCreated: onControllerCreated,
    );
  }

  factory PDFViewerWidget.assets(String asset, {PDFViewerControllerCallback<PDFViewerController>? onControllerCreated, bool clearCache = true}) {
    return PDFViewerWidget._(
      filePath: asset,
      isAssets: true,
      clearCache: clearCache,
      onControllerCreated: onControllerCreated,
    );
  }
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  late Jaguar server;
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel('FlutterPDFViewer', onMessageReceived: _onMessageReceived);

  late final String interceptUrl;

  late PDFViewerController _pdfViewerController;

  _onMessageReceived(JavaScriptMessage message) {
    Map<String, dynamic> msgMap = json.decode(message.message);
    log('Received message: $msgMap', name: 'pdf_js_viewer');
    if (msgMap['type'] == 'initialized') {
      _pdfViewerController._totalPage = msgMap['data'] as int;
      Future.delayed(Duration.zero, () {
        widget.onControllerCreated?.call(_pdfViewerController);
      });
    } else if (msgMap['type'] == 'pageChanged') {
      _pdfViewerController._page = msgMap['data'] as int;
      _pdfViewerController.onPageChanged?.call(_pdfViewerController._page);
      log('onPageChanged: ${_pdfViewerController._page}', name: 'pdf_js_viewer');
    }
  }

  @override
  void initState() {
    _pdfViewerController = PDFViewerController();
    _pdfViewerController._bindState(this);

    final random = Random();
    const minPort = 10000;
    const maxPort = 65535;
    int randomPort = minPort + random.nextInt(maxPort - minPort + 1);
    interceptUrl = 'http://127.0.0.1:$randomPort/pdfjs/web/viewer.html?file=/api/intercept';
    server = Jaguar(port: randomPort);
    _startServer();
    super.initState();
  }

  _startServer() async {
    server.addRoute(_serveFlutterAssets());
    server.get('/api/intercept', (Context ctx) async {
      List<int>? bytes;
      if (widget.fileData != null) {
        log('Processing Uint8List data：：：：', name: 'pdf_js_viewer');
        bytes = widget.fileData!;
      } else if (widget.filePath!.startsWith('http')) {
        log('Processing Network data：：：：', name: 'pdf_js_viewer');
        final response = await http.get(Uri.parse(widget.filePath!));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        }
      } else if (widget.isAssets) {
        log('Processing Assets data：：：：', name: 'pdf_js_viewer');
        assert(widget.filePath != null);
        final byteData = await rootBundle.load(widget.filePath!);
        bytes = Uint8List.view(byteData.buffer);
      } else {
        log('Processing File data：：：：', name: 'pdf_js_viewer');
        bytes = await File(widget.filePath!).readAsBytes();
      }
      return ByteResponse(body: bytes, mimeType: 'application/pdf ');
    });
    await server.serve();
    Future.delayed(Duration.zero, () {
      _controller.loadRequest(Uri.parse(interceptUrl));
    });
  }

  Route _serveFlutterAssets(
      {String path = '*', bool stripPrefix = true, String prefix = '', Map<String, String>? pathRegEx, ResponseProcessor? responseProcessor}) {
    Route route;
    int skipCount = -1;
    route = Route.get(path, (ctx) async {
      Iterable<String> segs = ctx.pathSegments;
      if (skipCount > 0) segs = segs.skip(skipCount);

      String lookupPath = segs.join('/') + (ctx.path.endsWith('/') ? 'index.html' : '');
      final body = (await rootBundle.load('packages/pdf_js_viewer/assets/$prefix$lookupPath')).buffer.asUint8List();

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
    if (widget.filePath != oldWidget.filePath || widget.fileData != oldWidget.fileData || widget.isAssets != oldWidget.isAssets) {
      _controller.reload();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    server.close();
    _controller.removeJavaScriptChannel('FlutterPDFViewer');
    _pdfViewerController._bindState(null);
    if (widget.clearCache) {
      _controller.clearCache();
      _controller.clearLocalStorage();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  set scrollMode(ScrollMode mode) {
    _controller.runJavaScriptReturningResult('PDFViewerApplication.pdfViewer.scrollMode=${mode.value}');
  }

  set spreadMode(SpreadMode mode) {
    _controller.runJavaScriptReturningResult('PDFViewerApplication.pdfViewer.spreadMode=${mode.value}');
  }

  Future<bool> jumpToPage(int page) async {
    try {
      await _controller.runJavaScriptReturningResult('PDFViewerApplication.page=$page');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> nextPage() async {
    try {
      final res = (await _controller.runJavaScriptReturningResult('PDFViewerApplication.pdfViewer.nextPage()')) as bool;
      return res;
    } catch (_) {
      return false;
    }
  }

  Future<bool> previousPage() async {
    try {
      final res = (await _controller.runJavaScriptReturningResult('PDFViewerApplication.pdfViewer.previousPage()')) as bool;
      return res;
    } catch (_) {
      return false;
    }
  }

  set removePageBorders(bool removePageBorders) {
    _controller.runJavaScript('window.viewer.classList.${removePageBorders ? 'add' : 'remove'}("removePageBorders");');
  }

  /// backgroundColor: #000000
  set backgroundColor(String backgroundColor) {
    _controller.runJavaScript('window.viewer.style.backgroundColor="$backgroundColor";');
  }

  hiddenScrollBar(bool hidden) {
    _controller.runJavaScript("PDFViewerApplication.pdfViewer.container.classList.${hidden ? 'add' : 'remove'}('no-scrollbar')");
  }
}

enum ScrollMode {
  vertical(0),
  horizontal(1),
  wrapped(2),
  page(3);

  final int value;

  const ScrollMode(this.value);
}

enum SpreadMode {
  none(0),
  odd(1),
  even(2);

  final int value;

  const SpreadMode(this.value);
}

class PDFViewerController {
  ValueChanged<int>? onPageChanged;
  SpreadMode _spreadMode = SpreadMode.none;
  ScrollMode _scrollMode = ScrollMode.vertical;

  int _totalPage = 0;
  int _page = 1;

  int get totalPage => _totalPage;

  int get currentPage => _page;

  set scrollMode(ScrollMode mode) {
    if (_viewerWidgetState != null) {
      _viewerWidgetState!.scrollMode = mode;
      _scrollMode = mode;
    }
  }

  ScrollMode get scrollMode => _scrollMode;

  set spreadMode(SpreadMode mode) {
    if (_viewerWidgetState != null) {
      _viewerWidgetState!.spreadMode = mode;
      _spreadMode = mode;
    }
  }

  SpreadMode get spreadMode => _spreadMode;

  void jumpToPage(int page) async {
    _viewerWidgetState?.jumpToPage(page);
  }

  void nextPage() async {
    _viewerWidgetState?.nextPage();
  }

  void previousPage() async {
    _viewerWidgetState?.previousPage();
  }

  set backgroundColor(String color) {
    _viewerWidgetState?.backgroundColor = color;
  }

  removePageBorders([bool remove = false]) {
    _viewerWidgetState?.removePageBorders = remove;
  }

  hiddenScrollBar(bool hidden) {
    _viewerWidgetState?.hiddenScrollBar(hidden);
  }

  _PDFViewerWidgetState? _viewerWidgetState;

  void _bindState(_PDFViewerWidgetState? state) {
    _viewerWidgetState = state;
  }
}
