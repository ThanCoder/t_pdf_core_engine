import 'package:flutter/material.dart';
import 'package:t_pdf_core_engine/t_pdf_core_engine.dart';
import 'package:t_pdf_example/pdf_page.dart';
import 'package:t_pdf_example/t_pdf_controller.dart';

class TPdfViewer extends StatefulWidget {
  final String path;
  final String? password;
  final TPdfController controller;
  const TPdfViewer({
    super.key,
    required this.path,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfViewer> createState() => _TPdfViewerState();
}

class _TPdfViewerState extends State<TPdfViewer> {
  late final TPdfController _controller;

  @override
  void initState() {
    initTPdfNativeLibrary();
    _controller = widget.controller;
    _controller.stateChangeListener.stream.listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    init();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void init() async {
    await _controller.loadPdf(
      widget.path,
      password: widget.password,
      getCurrentBuildContext: () => context,
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _controller.stateListener.stream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PdfLoadingState();

        if (state is PdfLoadingState) {
          return Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is PdfErrorState) {
          return Center(
            child: Text(state.error, style: TextStyle(color: Colors.red)),
          );
        }
        return InteractiveViewer(
          transformationController: _controller.transformationController,
          panAxis: PanAxis.free,
          panEnabled: _controller.panEnabled,
          scaleEnabled: _controller.panEnabled,
          maxScale: 8,
          minScale: 0.4,

          child: ListView.builder(
            controller: _controller.pdfScrollController,
            itemCount: _controller.pages.length,
            itemBuilder: (context, index) => _listItem(index),
            itemExtentBuilder: (index, dimensions) =>
                _controller.pages[index].height *
                _controller.itemExtentBuilderHeightPercen,
          ),
        );
      },
    );
  }

  Widget _listItem(int index) {
    if (_controller.isDarkMode) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white, BlendMode.difference),
        child: PdfPage(
          document: _controller.document,
          pageSize: _controller.pages[index],
          pageIndex: index,
          pageListener: _controller.pageListener,
        ),
      );
    }
    return PdfPage(
      document: _controller.document,
      pageSize: _controller.pages[index],
      pageIndex: index,
      pageListener: _controller.pageListener,
    );
  }
}
