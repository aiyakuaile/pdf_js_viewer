import 'package:flutter/material.dart';
import 'package:pdf_js_viewer/pdf_js_viewer.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PDFViewerController? _pdfViewerController;

  int _currentPage = 0;
  int _totalPage = 0;

  ScrollMode _scrollMode = ScrollMode.vertical;
  SpreadMode _spreadMode = SpreadMode.none;

  _onPageChanged(int page) {
    if (mounted) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFDetail'),
        actions: [
          DropdownButton<ScrollMode>(
            value: _scrollMode,
            onChanged: (ScrollMode? newValue) {
              if (newValue == null) return;
              _pdfViewerController!.scrollMode = newValue;
              if (mounted) {
                setState(() {
                  _scrollMode = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem<ScrollMode>(value: ScrollMode.vertical, child: Text('vertical')),
              DropdownMenuItem<ScrollMode>(value: ScrollMode.horizontal, child: Text('horizontal')),
              DropdownMenuItem<ScrollMode>(value: ScrollMode.wrapped, child: Text('wrapped')),
              DropdownMenuItem<ScrollMode>(value: ScrollMode.page, child: Text('page')),
            ],
            elevation: 8,
          ),
          DropdownButton<SpreadMode>(
            value: _spreadMode,
            onChanged: (SpreadMode? newValue) {
              if (newValue == null) return;
              _pdfViewerController!.spreadMode = newValue;
              if (mounted) {
                setState(() {
                  _spreadMode = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem<SpreadMode>(value: SpreadMode.none, child: Text('none')),
              DropdownMenuItem<SpreadMode>(value: SpreadMode.odd, child: Text('odd')),
              DropdownMenuItem<SpreadMode>(value: SpreadMode.even, child: Text('even')),
            ],
            elevation: 8,
          ),
        ],
      ),
      // body: PDFViewerWidget.data(data),
      // body: PDFViewerWidget.file(path),
      // body: PDFViewerWidget.network(path),
      body: Stack(children: [
        Positioned.fill(
            child: PDFViewerWidget.assets(
          'assets/compressed.pdf',
          onControllerCreated: (PDFViewerController controller) {
            if (mounted) {
              setState(() {
                _pdfViewerController = controller;
                _pdfViewerController!.onPageChanged = _onPageChanged;
                _totalPage = _pdfViewerController!.totalPage;
                _currentPage = _pdfViewerController!.currentPage;
              });
            }
          },
        )),
        Positioned(
          top: 10,
          left: 20,
          child: Container(
            height: 40,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '$_currentPage / $_totalPage',
              style: const TextStyle(fontSize: 17, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 20,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.white,
                  onPressed: () {
                    _pdfViewerController!.previousPage();
                  },
                ),
                Text(
                  '$_currentPage',
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.white,
                  onPressed: () {
                    _pdfViewerController!.nextPage();
                  },
                ),
              ],
            ),
          ),
        )
      ]),
    );
  }
}
