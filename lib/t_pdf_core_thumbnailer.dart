import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:t_pdf_core_engine/t_pdf_core_engine.dart';

class TPdfCoreThumbnailer {
  static Future<Uint8List?> extractImage(
    String pdfPath, {
    int pageIndex = 0,
    int width = 1024,
    int height = 768,
    TImageFormat format = TImageFormat.jpg,
    int quality = 100,
  }) async {
    return Isolate.run(() async {
      final dom = TDocument();
      try {
        initTPdfNativeLibrary();

        final page = TPdfPage();

        dom.open(pdfPath);
        page.open(dom, pageIndex: pageIndex);

        final imgData = page.getImage(
          width: width,
          height: height,
          format: format,
          quality: quality,
        );

        page.close();

        return imgData;
      } catch (e) {
        // ignore: avoid_print
        print(e.toString());
        return null;
      } finally {
        dom.close();
      }
    });
  }

  /// overrideExistsImage=true ? will return false;
  ///
  /// errr == true ? return false
  ///
  /// writed ? return true;
  ///
  static Future<bool> extractImageAndSave(
    String pdfPath, {
    required String savePath,
    bool overrideExistsImage = false,
    int pageIndex = 0,
    int width = 1024,
    int height = 768,
    TImageFormat format = TImageFormat.jpg,
    int quality = 100,
  }) async {
    final saveFile = File(savePath);
    if (saveFile.existsSync() && !overrideExistsImage) return false;

    final data = await extractImage(
      pdfPath,
      format: format,
      height: height,
      pageIndex: pageIndex,
      quality: quality,
      width: width,
    );
    if (data == null) return false;
    await saveFile.writeAsBytes(data);
    return true;
  }
}
