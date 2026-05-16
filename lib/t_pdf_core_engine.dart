import 'dart:ffi';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import 't_pdf_core_engine_bindings_generated.dart' as bindings;

export 'package:t_pdf_core_engine/core/t_document.dart';
export 'package:t_pdf_core_engine/core/t_pdf_page.dart';

// ********** init lib **************

void initTPdfNativeLibrary() {
  bindings.FPDF_InitLibrary();
}

void initTPdfNativeLibraryWithConfig(
  Pointer<bindings.FPDF_LIBRARY_CONFIG_> config,
) {
  bindings.FPDF_InitLibraryWithConfig(config);
}

// ********** page **************

bindings.FPDF_PAGE loadPage(
  Pointer<bindings.fpdf_document_t__> document,
  int pageIndex,
) {
  return bindings.FPDF_LoadPage(document, pageIndex);
}

void closePage(bindings.FPDF_PAGE page) {
  if (page == ffi.nullptr) return;
  bindings.FPDF_ClosePage(page);
}

// ********** document **************

bindings.FPDF_DOCUMENT loadDocument(String filePath, String? password) {
  return using((arena) {
    Pointer<Char> filePathP = filePath
        .toNativeUtf8(allocator: arena)
        .cast<ffi.Char>();
    Pointer<Char> passwordP = ffi.nullptr;
    if (password != null) {
      passwordP = password.toNativeUtf8(allocator: arena).cast<ffi.Char>();
    }
    final doc = bindings.FPDF_LoadDocument(filePathP, passwordP);
    if (doc == ffi.nullptr) {
      // လက်တွေ့ သုံးတဲ့အခါ Error ဘာတက်လဲ သိရအောင် ခေါ်ထားသင့်ပါတယ်
      final errorCode = bindings.FPDF_GetLastError();
      // ignore: avoid_print
      print("PDF Load လုပ်ရတာ မအောင်မြင်ပါ။ Error Code: $errorCode");
      throw Exception('PDF Load Failed!.Error Code: $errorCode"');
    }
    return doc;
  });
}

void closeDocument(bindings.FPDF_DOCUMENT document) {
  if (document == ffi.nullptr) return;
  bindings.FPDF_CloseDocument(document);
}
