import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_core_engine/core/t_document.dart';
import 'package:t_pdf_core_engine/core/t_pdf_page.dart';
import 'package:t_pdf_example/pdf_image_cache_manger.dart';
import 'package:t_pdf_example/pdf_page.dart';
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
    // WidgetsBinding.instance.addPostFrameCallback((_) => init());
    init();
    super.initState();
  }

  @override
  void dispose() {
    document.close();
    pageListener.close();
    PdfImageCacheManger.instance.clear();
    ThanPkg.platform.toggleFullScreen(isFullScreen: false);
    transformationController.dispose();
    super.dispose();
  }

  bool isLoading = false;
  final document = TDocument();
  // List<TPagePreview> pages = [];
  List<TPageSize> pages = [];
  final pageListener = StreamController<int>.broadcast();
  final pdfScrollController = ScrollController();
  int _currentPage = 0;
  String? error;
  double itemExtentBuilderHeightPercen = 0.5;
  bool isFullscreen = false;
  bool isDarkMode = false;
  bool panEnabled = false;
  final transformationController = TransformationController();
  double currentScale = 1;

  void init() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      document.open(widget.path);
      pages = await TDocument.getAllPageSizesAsync(widget.path);
      // pages = await TDocument.getAllRawImageCachePageSizesAsync(widget.path);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      // await Future.delayed(Duration(seconds: 1));
      // _goToPage(10);
      // _setScale(1.5);
    } catch (e) {
      if (!mounted) return;
      error = e.toString();
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: isFullscreen
            ? null
            : AppBar(
                title: Text('Pdf Reader'),
                bottom: PreferredSize(
                  preferredSize: Size(MediaQuery.of(context).size.width, 50),
                  child: _header,
                ),
              ),
        body: isLoading
            ? Center(child: CircularProgressIndicator.adaptive())
            : error != null
            ? Center(child: Text(error!))
            : _listView,
      ),
    );
  }

  Widget get _header {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          StreamBuilder(
            stream: pageListener.stream,
            builder: (context, snapshot) {
              _currentPage = snapshot.data ?? 0;
              return TextButton(
                onPressed: _showGoToDialog,
                child: Text('${document.pageCount - 1}/$_currentPage'),
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
              isDarkMode = !isDarkMode;
              setState(() {});
            },
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            onPressed: () {
              panEnabled = !panEnabled;
              setState(() {});
            },
            icon: Icon(panEnabled ? Icons.lock_open : Icons.lock),
          ),

          IconButton(onPressed: () {}, icon: Icon(Icons.zoom_in)),
        ],
      ),
    );
  }

  Widget get _listView {
    return GestureDetector(
      onDoubleTap: () {
        isFullscreen = !isFullscreen;
        ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
        setState(() {});
      },
      child: InteractiveViewer(
        transformationController: transformationController,
        panAxis: PanAxis.free,
        panEnabled: panEnabled,
        scaleEnabled: panEnabled,
        onInteractionEnd: (details) {
          // 💡 Controller ထံမှ လက်ရှိ ရောက်နေသော Scale ကို လှမ်းယူခြင်း
          final Matrix4 currentMatrix = transformationController.value;
          final double currentScale = currentMatrix.getMaxScaleOnAxis();

          print('လက်ရှိ Zoom ချဲ့ထားတဲ့ ပမာဏ (Scale): $currentScale');
          this.currentScale = currentScale;

          // ဥပမာ - User လက်လွှတ်လိုက်တဲ့အချိန်မှာ ၃ ဆထက် ပိုကြီးနေရင် ၂ ဆပဲ ပြန်ထားချင်ရင် အခုလို စစ်လို့ရပါပြီ
          if (currentScale > 3.0) {
            // မိမိလိုချင်တဲ့ scale ကို ပြန် set လုပ်လို့ရပါတယ်
            _setScale(2.0);
          }
        },
        child: ListView.builder(
          controller: pdfScrollController,
          itemCount: pages.length,
          itemBuilder: (context, index) => _listItem(index),
          itemExtentBuilder: (index, dimensions) =>
              pages[index].height * itemExtentBuilderHeightPercen,
        ),
      ),
    );
  }

  Widget _listItem(int index) {
    return PdfPage(
      document: document,
      pageSize: pages[index],
      pageIndex: index,
      pageListener: pageListener,
    );
  }

  void _setScale(double targetScale) {
    // ၁။ လက်ရှိ စာမျက်နှာရဲ့ Size မူရင်းကို ယူမယ်
    // final page = pages[_currentPage];
    // final double originalWidth = page.width;
    // final double originalHeight = page.height;

    // // ၅။ Matrix ဖန်တီးပြီး အလယ်ရွှေ့ခြင်းနှင့် ချဲ့ခြင်းကို တစ်ခါတည်း လုပ်ဆောင်မယ်
    // final Matrix4 matrix = Matrix4.identity()
    //   ..translate(xOffset, yOffset)
    //   ..scaleByDouble(targetScale);

    // // ၆။ UI ပြောင်းလဲရန် Controller ထံ တန်ဖိုးပေးလိုက်မယ်
    // transformationController.value = matrix;
  }

  void _zoomIn() {
    // လက်ရှိ ရောက်နေတဲ့ Matrix ကို ယူမယ်
    final Matrix4 currentMatrix = transformationController.value;
    // လက်ရှိ ရောက်နေတဲ့ Scale ပမာဏကို ဆွဲထုတ်မယ်
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // ဥပမာ- အမြင့်ဆုံး ၅ ဆထက် ကျော်လို့မရအောင် ကန့်သတ်မယ်
    if (currentScale >= 5.0) return;

    // တစ်ခါနှိပ်ရင် ၁.၅ ဆ ချဲ့မယ် (စိတ်ကြိုက်ပြင်နိုင်ပါတယ်)
    // _animateToScale(currentScale * 1.5);
    // transformationController.value = currentMatrix.copyInto(arg)
  }

  void _zoomOut() {
    final Matrix4 currentMatrix = transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // မူရင်း Size (၁ ဆ) ထက် ငယ်သွားလို့မရအောင် ကန့်သတ်မယ်
    if (currentScale <= 1.0) return;

    // တစ်ခါနှိပ်ရင် ၁.၅ ဆ ပြန်ကျုံ့မယ်
    double targetScale = currentScale / 1.5;
    if (targetScale < 1.0) targetScale = 1.0;
  }

  void _goToPage(int pageNumber) {
    final page = pages[pageNumber - 1];
    pdfScrollController.jumpTo(
      (page.height * itemExtentBuilderHeightPercen) * pageNumber,
    );
  }

  void _showGoToDialog() {
    showTReanmeDialog(
      context,
      text: _currentPage.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputType: TextInputType.number,
      submitText: 'Go To',
      onCheckIsError: (text) {
        if (text.isEmpty) return 'Number Required!';
        final num = int.tryParse(text);
        if (num == null) return 'Number Required!';
        if (num > pages.length) {
          return 'Page: $num > ${pages.length} Bigger!';
        }
        return null;
      },
      onSubmit: (text) {
        final num = int.parse(text);
        _goToPage(num);
      },
    );
  }
}
