import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_example/t_pdf_controller.dart';
import 'package:t_pdf_example/t_pdf_viewer.dart';
import 'package:t_widgets/functions/dialog_func.dart';
import 'package:than_pkg/than_pkg.dart';

class PdfReader extends StatefulWidget {
  final String path;
  const PdfReader({super.key, required this.path});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  @override
  void initState() {
    super.initState();
    controller.currentScaleListener.listen((scale) {
      print('current scale: $scale');
    });
    controller.currentState.listen((state) {
      if (state is PdfLoadedState) {
        controller.setScale(2.0736);
        controller.goToPage(2);
      }
    });
  }

  @override
  void dispose() {
    ThanPkg.platform.toggleFullScreen(isFullScreen: false);
    super.dispose();
  }

  bool isFullscreen = false;
  final controller = TPdfController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: controller.stateChangeListener.stream,
      builder: (context, asyncSnapshot) {
        return Theme(
          data: controller.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            appBar: isFullscreen
                ? null
                : AppBar(
                    title: Text('Pdf Reader'),
                    bottom: PreferredSize(
                      preferredSize: Size(
                        MediaQuery.of(context).size.width,
                        50,
                      ),
                      child: _header,
                    ),
                  ),
            body: _body,
          ),
        );
      },
    );
  }

  Widget get _header {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          StreamBuilder(
            stream: controller.pageListener.stream,
            builder: (context, snapshot) {
              return TextButton(
                onPressed: _showGoToDialog,
                child: Text(
                  '${controller.currentPage}/${controller.pageCount - 0}',
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              isFullscreen = !isFullscreen;
              ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
              setState(() {});
            },
            icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
          IconButton(
            onPressed: () {
              controller.setDarkMode(!controller.isDarkMode);
            },
            icon: Icon(
              controller.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),

          // IconButton(
          //   onPressed: () {

          //   },
          //   icon: Icon(panEnabled ? Icons.lock_open : Icons.lock),
          // ),
          IconButton(onPressed: controller.zoomIn, icon: Icon(Icons.zoom_in)),
          IconButton(onPressed: controller.zoomOut, icon: Icon(Icons.zoom_out)),
          IconButton(
            onPressed: controller.centerAndResetZoom,
            icon: Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  Widget get _body {
    return _listView;
  }

  Widget get _listView {
    return GestureDetector(
      onDoubleTap: () {
        isFullscreen = !isFullscreen;
        ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
        setState(() {});
      },
      child: TPdfViewer(path: widget.path, controller: controller),
    );
  }

  void _showGoToDialog() {
    showTReanmeDialog(
      context,
      text: controller.currentPage.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputType: TextInputType.number,
      submitText: 'Go To',
      onCheckIsError: (text) {
        if (text.isEmpty) return 'Number Required!';
        final num = int.tryParse(text);
        if (num == null) return 'Number Required!';
        if (num > controller.pageCount) {
          return 'Page: $num > ${controller.pageCount} Bigger!';
        }
        return null;
      },
      onSubmit: (text) {
        final num = int.parse(text);
        // _goToPage(num);
        controller.goToPage(num);
      },
    );
  }
}
