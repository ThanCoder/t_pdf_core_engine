import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:t_pdf_core_engine/core/t_document.dart';
import 'package:t_pdf_core_engine/core/t_pdf_page.dart';
import 'package:t_pdf_example/pdf_image_cache_manger.dart';
import 'package:visibility_detector/visibility_detector.dart'; // 💡 Focus သိရန် သုံးရပါမည်

class PdfPage extends StatefulWidget {
  final TDocument document;
  final TPageSize pageSize;
  final int pageIndex;
  final StreamController<int>? pageListener;
  const PdfPage({
    super.key,
    required this.document,
    required this.pageSize,
    required this.pageIndex,
    this.pageListener,
  });

  @override
  State<PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  final page = TPdfPage();
  bool _isLoading = false;
  bool _hasRendered = false; // တစ်ကြိမ် Render ပြီးရင် ထပ်မလုပ်ဖို့ မှတ်ထားရန်

  Uint8List? get getImageCache =>
      PdfImageCacheManger.instance.getCache(widget.pageIndex);

  /// 💡 စာမျက်နှာ မျက်နှာပြင်ပေါ် ရောက်လာပြီး Focus ဖြစ်မှ ခေါ်မည့် function
  void _renderPageOnFocus() async {
    // ပုံတစ်ခါဆွဲပြီးသား ဖြစ်နေရင် သို့မဟုတ် လက်ရှိဆွဲနေတုန်းဆိုရင် ထပ်မလုပ်တော့ဘူး
    if (_hasRendered || _isLoading) return;
    if (getImageCache != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 💡 ဒီနေရာကျမှ တကယ့် Native Page ကို ဖွင့်ပြီး ပုံဆွဲပါတယ်
      page.open(widget.document, pageIndex: widget.pageIndex);

      final bytes = page.getImage(
        width: page.pageWidth.toInt(),
        height: page.pageHeight.toInt(),
        // height: widget.globalPageHeight.toInt(),
      );

      PdfImageCacheManger.instance.setCache(widget.pageIndex, bytes);

      page.close();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasRendered = true; // အောင်မြင်စွာ ဆွဲပြီးကြောင်း မှတ်သား
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(
    //   'Count: ${PdfImageCacheManger.instance.cacheCount} - Size: ${PdfImageCacheManger.instance.cacheSize.fileSizeLabel()}',
    // );

    return VisibilityDetector(
      key: Key('pdf-page-${widget.pageIndex}'),
      onVisibilityChanged: (VisibilityInfo info) {
        // print('index: ${widget.pageIndex} - info: ${info.visibleFraction}');
        if (info.visibleFraction > 0.1) {
          // print('show: ${widget.pageIndex}');
          widget.pageListener?.add(widget.pageIndex + 1);
          _renderPageOnFocus();
        }
      },
      child: SizedBox(
        width: widget.pageSize.width,
        height: widget.pageSize.height,
        // height: widget.globalPageHeight,
        child: _imageWidget,
      ),
    );
  }

  Widget get _imageWidget {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (getImageCache == null) {
      return Center(child: Container(color: Colors.white));
      // return RawThumbnailWidget(rawBytes: widget.pageSize.rawThumbnailBytes!);
    }
    return Image.memory(getImageCache!);
  }
}
