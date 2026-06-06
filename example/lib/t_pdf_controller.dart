import 'dart:async';

import 'package:flutter/material.dart';
import 'package:t_pdf_core_engine/core/t_document.dart';
import 'package:t_pdf_core_engine/core/t_pdf_page.dart';
import 'package:t_pdf_example/pdf_image_cache_manger.dart';
import 'package:vector_math/vector_math_64.dart' as v4;

abstract class PdfState {}

abstract class PdfStateEvent {}

class PdfLoadingState extends PdfState {}

class PdfViewerWidgetAttachState extends PdfState {}

class PdfLoadedState extends PdfState {}

class PdfErrorState extends PdfState {
  final String error;
  PdfErrorState(this.error);
}

class PdfDarkModeChangeEvent extends PdfStateEvent {}

class TPdfController {
  int _currentPage = 0;
  int _pageCount = 0;
  bool _isDarkMode = false;
  bool _isPanEnable = false;
  final double _zoomFactor = 1.2;
  List<TPageSize> _pages = [];
  bool panEnabled = false;

  final pageListener = StreamController<int>.broadcast();
  final currentZoomListener = StreamController<double>.broadcast();
  final stateListener = StreamController<PdfState>.broadcast();
  final stateChangeListener = StreamController<PdfStateEvent>.broadcast();

  final document = TDocument();
  final pdfScrollController = ScrollController();
  double itemExtentBuilderHeightPercen = 0.5;
  final transformationController = TransformationController();

  int get pageCount => _pageCount;
  int get currentPage => _currentPage;
  bool get isDarkMode => _isDarkMode;
  double get zoomFactor => _zoomFactor;
  bool get isPanEnable => _isPanEnable;
  List<TPageSize> get pages => _pages;
  Stream<double> get currentScaleListener => currentZoomListener.stream;
  Stream<PdfState> get currentState => stateListener.stream;

  void goToPage(int pageNumber) {
    if (!pdfScrollController.hasClients) return;

    final page = pages[pageNumber - 1];
    pdfScrollController.jumpTo(
      (page.height * itemExtentBuilderHeightPercen) * pageNumber,
    );
  }

  void setPanEnable(bool enable) {
    _isPanEnable = enable;
  }

  void setDarkMode(bool darkMode) {
    _isDarkMode = darkMode;
    stateChangeListener.add(PdfDarkModeChangeEvent());
  }

  void zoomIn() {
    _zoom(_zoomFactor);
  }

  void zoomOut() {
    _zoom(1 / _zoomFactor);
  }

  void setScale(double scale) {
    _zoom(scale);
  }

  void centerAndResetZoom() {
    final (centerX, centerY) = _centerSize;

    final currentZoom = transformationController.value.clone();

    currentZoom.translateByVector3(v4.Vector3(centerX, centerY, 0));

    currentZoom.translateByVector3(v4.Vector3(-centerX, -centerY, 0));

    transformationController.value = currentZoom;
    // change scale
    currentZoomListener.add(currentScale);
  }

  void _zoom(double factor) {
    final (centerX, centerY) = _centerSize;

    final currentZoom = transformationController.value.clone();

    currentZoom.translateByVector3(v4.Vector3(centerX, centerY, 0));
    currentZoom.scaleByDouble(factor, factor, 1.0, 1.0);
    currentZoom.translateByVector3(v4.Vector3(-centerX, -centerY, 0));

    transformationController.value = currentZoom;
    // change scale
    currentZoomListener.add(currentScale);
  }

  double get currentScale {
    // transformationController ကနေ လက်ရှိ matrix ကို ယူတယ်
    final Matrix4 matrix = transformationController.value;

    // အဲဒီ matrix ထဲကနေ scale တန်ဖိုးကို လှမ်းထုတ်တယ်
    return matrix.getMaxScaleOnAxis();
  }

  late final BuildContext Function() _getCurrentBuildContext;

  /// (centerX, centerY)
  (double, double) get _centerSize {
    final size = MediaQuery.of(_getCurrentBuildContext()).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    return (centerX, centerY);
  }

  Future<void> loadPdf(
    String path, {
    required BuildContext Function() getCurrentBuildContext,
    String? password,
  }) async {
    try {
      _getCurrentBuildContext = getCurrentBuildContext;
      stateListener.add(PdfLoadingState());

      document.open(path);
      _pages = await TDocument.getAllPageSizesAsync(path, password: password);
      _currentPage = 1;
      _pageCount = _pages.length;
      pageListener.add(_currentPage);

      stateListener.add(PdfViewerWidgetAttachState());
      Future.delayed(Duration(milliseconds: 800)).then((value) {
        if (pdfScrollController.hasClients) {
          stateListener.add(PdfLoadedState());
        }
      });

      // listener
      pageListener.stream.listen((page) {
        _currentPage = page;
      });
    } catch (e) {
      stateListener.add(PdfErrorState(e.toString()));
    }
  }

  void dispose() {
    document.close();
    pageListener.close();
    stateListener.close();
    currentZoomListener.close();
    pdfScrollController.dispose();
    stateChangeListener.close();
    PdfImageCacheManger.instance.clear();
    transformationController.dispose();
  }
}
