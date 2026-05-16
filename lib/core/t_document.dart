import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:t_pdf_core_engine/t_pdf_core_engine.dart';

import '../t_pdf_core_engine_bindings_generated.dart' as bindings;

class TDocument {
  bindings.FPDF_DOCUMENT _docPointer = ffi.nullptr;
  bindings.FPDF_DOCUMENT get docPointer => _docPointer;

  void open(String pdfPath, {String? password}) {
    _docPointer = loadDocument(pdfPath, password);
  }

  /// if `err` -> -1;
  int get pageCount {
    if (_docPointer == ffi.nullptr) return -1;
    return bindings.FPDF_GetPageCount(_docPointer);
  }

  /// 💡 Page တစ်ခုလုံးကို မဖွင့်ဘဲ စာမျက်နှာရဲ့ Size (Width, Height) ကိုပဲ သီးသန့် ယူမည့် function
  TPageSize getPageSize(int pageIndex) {
    if (_docPointer == ffi.nullptr) {
      throw Exception("ဖွင့်ထားသော PDF Document မရှိပါ။");
    }

    // allocation အတွက် using block ကို သုံးရင် ပိုစိတ်ချရပါတယ်
    return using((Arena arena) {
      // C++ ရဲ့ double* နေရာမှာ သုံးဖို့ Dart Memory allocate လုပ်မယ်
      final ffi.Pointer<ffi.Double> widthPtr = arena.allocate<ffi.Double>(
        ffi.sizeOf<ffi.Double>(),
      );
      final ffi.Pointer<ffi.Double> heightPtr = arena.allocate<ffi.Double>(
        ffi.sizeOf<ffi.Double>(),
      );

      // PDFium function ကို လှမ်းခေါ်မယ်
      final int result = bindings.FPDF_GetPageSizeByIndex(
        _docPointer,
        pageIndex,
        widthPtr,
        heightPtr,
      );

      // result == 0 ဆိုရင် အလုပ်မလုပ်တာ (Fail ဖြစ်တာ) ပါ
      if (result == 0) {
        throw Exception("Page index ($pageIndex) ရဲ့ Size ကို ယူ၍မရပါ။");
      }

      // pointer ထဲက တန်ဖိုးတွေကို Dart variable အဖြစ် ပြန်ထုတ်ယူမယ်
      // return {'width': widthPtr.value, 'height': heightPtr.value};
      return TPageSize(width: widthPtr.value, height: heightPtr.value);
    });
  }

  /// 💡 PDF တစ်စောင်လုံးမှာရှိတဲ့ စာမျက်နှာအားလုံးရဲ့ Size တွေကို
  /// တစ်ခါတည်း List အနေနဲ့ ကြိုယူထားချင်ရင် သုံးရန်
  List<TPageSize> getAllPageSizes() {
    final List<TPageSize> sizes = [];
    final count = pageCount;

    for (int i = 0; i < count; i++) {
      sizes.add(getPageSize(i));
    }
    return sizes;
  }

  void close() {
    closeDocument(_docPointer);
  }

  /// 💡 Pure Dart အတွက် Isolate.run ကို သုံးပြီး ရေးထားတဲ့ Async function
  static Future<List<TPageSize>> getAllPageSizesAsync(
    String filePath, {
    String? password,
  }) async {
    // Isolate.run က နောက်ကွယ်က Thread (Isolate) အသစ်တစ်ခုကို ချက်ချင်း ဆောက်ပြီး မောင်းပေးပါတယ်

    return await Isolate.run(() {
      // ⚠️ Thread အသစ်ဖြစ်လို့ သူ့အထဲမှာ PDFium Library ကို တစ်ခါ ထပ်မံ Init လုပ်ပေးရပါမယ်
      bindings.FPDF_InitLibrary();

      final List<TPageSize> sizes = [];

      using((Arena arena) {
        final ffi.Pointer<ffi.Char> filePathP = filePath
            .toNativeUtf8(allocator: arena)
            .cast<ffi.Char>();
        ffi.Pointer<ffi.Char> passwordP = ffi.nullptr;
        if (password != null) {
          passwordP = password.toNativeUtf8(allocator: arena).cast<ffi.Char>();
        }

        // PDF ဖွင့်မယ်
        final docPointer = bindings.FPDF_LoadDocument(filePathP, passwordP);
        if (docPointer == ffi.nullptr) {
          return sizes;
        }

        final pageCount = bindings.FPDF_GetPageCount(docPointer);

        // Memory allocation ကို Loop အပြင်မှာ တစ်ခါတည်း ကြိုလုပ်မယ်
        final ffi.Pointer<ffi.Double> widthPtr = arena.allocate<ffi.Double>(
          ffi.sizeOf<ffi.Double>(),
        );
        final ffi.Pointer<ffi.Double> heightPtr = arena.allocate<ffi.Double>(
          ffi.sizeOf<ffi.Double>(),
        );

        // Size တွေ အကုန်လုံး ဆွဲထုတ်မယ်
        for (int i = 0; i < pageCount; i++) {
          final int result = bindings.FPDF_GetPageSizeByIndex(
            docPointer,
            i,
            widthPtr,
            heightPtr,
          );
          if (result != 0) {
            sizes.add(
              TPageSize(width: widthPtr.value, height: heightPtr.value),
            );
          }
        }

        // ပြီးရင် သေချာပေါက် ပြန်ပိတ်မယ်
        bindings.FPDF_CloseDocument(docPointer);
      });

      // ရလာတဲ့ ကုန်ချော List ကြီးကို UI Thread (Main Isolate) ဆီ ပြန်ပေးလိုက်မယ်
      return sizes;
    });
  }

  ///raw image cache
  static Future<List<TPagePreview>> getAllRawImageCachePageSizesAsync(
    String filePath, {
    String? password,
    int width = 50,
    int height = 50,
  }) async {
    return await Isolate.run(() {
      bindings.FPDF_InitLibrary();

      final List<TPagePreview> previews = [];

      using((Arena arena) {
        final ffi.Pointer<ffi.Char> filePathP = filePath
            .toNativeUtf8(allocator: arena)
            .cast<ffi.Char>();
        ffi.Pointer<ffi.Char> passwordP = ffi.nullptr;
        if (password != null) {
          passwordP = password.toNativeUtf8(allocator: arena).cast<ffi.Char>();
        }

        final docPointer = bindings.FPDF_LoadDocument(filePathP, passwordP);
        if (docPointer == ffi.nullptr) return previews;

        final pageCount = bindings.FPDF_GetPageCount(docPointer);

        final ffi.Pointer<ffi.Double> widthPtr = arena.allocate<ffi.Double>(
          ffi.sizeOf<ffi.Double>(),
        );
        final ffi.Pointer<ffi.Double> heightPtr = arena.allocate<ffi.Double>(
          ffi.sizeOf<ffi.Double>(),
        );

        for (int i = 0; i < pageCount; i++) {
          final int result = bindings.FPDF_GetPageSizeByIndex(
            docPointer,
            i,
            widthPtr,
            heightPtr,
          );

          if (result != 0) {
            final originalWidth = widthPtr.value;
            final originalHeight = heightPtr.value;

            // --- 📸 THUMBNAIL GENERATION START ---
            // Page Object ကို ခေတ္တဖွင့်မယ်
            final page = TPdfPage();
            page.openPointer(docPointer, i);
            final rawData = page.getRawThumbnail(width: width, height: height);

            ///page close
            page.close();
            // --- 📸 THUMBNAIL GENERATION END ---

            previews.add(
              TPagePreview(
                width: originalWidth,
                height: originalHeight,
                rawThumbnailBytes: rawData, // ဤနေရာတွင် ပုံကပ်ပါသွားမည်
              ),
            );
          }
        }

        // close dom
        bindings.FPDF_CloseDocument(docPointer);
      });

      return previews;
    });
  }
}
