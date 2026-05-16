// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:t_pdf_core_engine/t_pdf_core_engine.dart';

import '../t_pdf_core_engine_bindings_generated.dart' as bindings;

enum TImageFormat {
  /// Encode an [image] to the JPEG format.
  jpg,

  /// Encode an image to the PNG format.
  png,

  /// Encode an [Image] to the BMP format.
  bmp,

  /// Encode an [Image] to the CUR format.
  cur,

  /// Encode an image to the ICO format.
  ico,
}
// void test(){
//   img.encodeIco(image)
// }

class TPageSize {
  final double width;
  final double height;
  const TPageSize({required this.width, required this.height});
}

class TPagePreview {
  final double width;
  final double height;
  final Uint8List rawThumbnailBytes; // ⚠️ ဝါးဝါး သေးသေး Thumbnail ပုံထည့်ရန်

  TPagePreview({
    required this.width,
    required this.height,
    required this.rawThumbnailBytes,
  });
}

class TPdfPage {
  TPdfPage();

  bindings.FPDF_PAGE _pagePointer = ffi.nullptr;
  bindings.FPDF_PAGE get pagePointer => _pagePointer;

  void open(TDocument document, {int pageIndex = 0}) {
    _pagePointer = loadPage(document.docPointer, pageIndex);
  }

  void openPointer(bindings.FPDF_DOCUMENT documentPoiner, int pageIndex) {
    _pagePointer = loadPage(documentPoiner, pageIndex);
  }

  double get pageWidth {
    if (_pagePointer == ffi.nullptr) return -1;
    return bindings.FPDF_GetPageWidth(_pagePointer);
  }

  double get pageHeight {
    if (_pagePointer == ffi.nullptr) return -1;
    return bindings.FPDF_GetPageHeight(_pagePointer);
  }

  Uint8List getImage({
    int width = 1024,
    int height = 768,
    TImageFormat format = TImageFormat.jpg,
    int quality = 100,
  }) {
    // ၁။ FPDFBitmap_Create ကို သုံးပြီး ပိုရိုးရှင်းစွာ Bitmap ဆောက်မယ်
    // နောက်ဆုံး parameter 0 က alpha မသုံးဘူး (BGRx format) လို့ ပြောတာပါ
    final bitmap = bindings.FPDFBitmap_Create(width, height, 0);
    // 💡 ဖြည့်စွက်ချက်: Background ကို အဖြူရောင် (0xFFFFFFFF) အရင် ချယ်ပေးရပါမယ်
    // ဒါမှ စာရွက်ဖြူဖြူပေါ်မှာ စာသားတွေ ကြည်ကြည်လင်လင် ပေါ်မှာ ဖြစ်ပါတယ်
    bindings.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
    // render လုပ်မယ်
    bindings.FPDF_RenderPageBitmap(
      bitmap,
      _pagePointer,
      0,
      0,
      width,
      height,
      0,
      0,
    );

    final buffer = bindings.FPDFBitmap_GetBuffer(bitmap);

    // ၅။ Pointer ကနေ Dart ရဲ့ Uint8List (Byte Array) အဖြစ် ပြောင်းလဲမယ်
    final int totalBytes = width * height * 4; // Width x Height x 4 bytes
    final Uint8List rawBytes = buffer.cast<ffi.Uint8>().asTypedList(totalBytes);

    // ၃။ Raw Bytes ကို package:image ရဲ့ Image Object အဖြစ် ပြောင်းမယ်
    final img.Image imageObj = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rawBytes.buffer,
      order: img.ChannelOrder.bgra,
    );

    // bindings.FPDF_RenderPage_Close(page)
    bindings.FPDFBitmap_Destroy(bitmap);

    // ၅။ 💡 ရွေးချယ်လိုက်တဲ့ Format အလိုက် Encode လုပ်ပေးခြင်း
    Uint8List finalEncodedBytes;

    if (format == TImageFormat.jpg) {
      // JPG ဆိုရင် quality option ပါ တစ်ခါတည်း သတ်မှတ်မယ်
      finalEncodedBytes = Uint8List.fromList(
        img.encodeJpg(imageObj, quality: quality),
      );
    } else if (format == TImageFormat.bmp) {
      finalEncodedBytes = Uint8List.fromList(img.encodeBmp(imageObj));
    } else if (format == TImageFormat.cur) {
      finalEncodedBytes = Uint8List.fromList(img.encodeCur(imageObj));
    } else if (format == TImageFormat.ico) {
      finalEncodedBytes = Uint8List.fromList(img.encodeIco(imageObj));
    } else {
      // PNG ဆိုရင် အကောင်းဆုံး format အတိုင်း encode လုပ်မယ်
      finalEncodedBytes = Uint8List.fromList(img.encodePng(imageObj));
    }

    // ၆။ ကုန်ချော Image bytes ကို return ပြန်မယ်
    return finalEncodedBytes;
  }

  Uint8List getRawThumbnail({
    int width =
        80, // 💡 ဝါးဝါးလေးပဲ လိုချင်လို့ Size ကို တအားသေးပစ်မယ် (ဥပမာ 80x100 ဝန်းကျင်)
    int height = 110,
  }) {
    // ၁။ Bitmap အသေးလေး ဆောက်မယ်
    final bitmap = bindings.FPDFBitmap_Create(width, height, 0);

    // ၂။ Background အဖြူချယ်မယ်
    bindings.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);

    // ၃။ Render လုပ်တဲ့အခါ အမြန်ဆုံးဖြစ်အောင်နဲ့ စာသားတွေ ဝါးသွားအောင်
    // FPDF_RENDER_NO_SMOOTHTEXT (0x1000) နဲ့ FPDF_LCD_TEXT (0x02) flag တွေကို သုံးနိုင်ပါတယ်
    // သို့မဟုတ် 0 ထားလည်း size သေးရင် သူ့အလိုလို ဝါးသွားမှာပါ
    bindings.FPDF_RenderPageBitmap(
      bitmap,
      _pagePointer,
      0,
      0,
      width,
      height,
      0,
      0, // flags: 0 ထားရင် size သေးတဲ့အတွက် အလိုအလျောက် pixelated ဖြစ်ပြီး ဝါးသွားပါမယ်
    );

    final buffer = bindings.FPDFBitmap_GetBuffer(bitmap);
    final int totalBytes = width * height * 4; // BGRA format

    // ၄။ Pointer ကနေ Dart Byte Array ပြောင်းမယ်
    // (.clone() သို့မဟုတ် Uint8List.fromList သုံးပြီး C memory ကနေ Dart memory ထဲ ကူးယူပါ)
    final Uint8List rawBytes = Uint8List.fromList(
      buffer.cast<ffi.Uint8>().asTypedList(totalBytes),
    );

    // ၅။ Native bitmap ကို ချက်ချင်းဖျက်မယ်
    bindings.FPDFBitmap_Destroy(bitmap);

    // ⚠️ PNG/JPG encode မလုပ်တော့ဘဲ Raw RGBA/BGRA bytes အတိုင်း တိုက်ရိုက် return ပြန်တယ်
    return rawBytes;
  }

  void close() {
    closePage(_pagePointer);
  }
}
