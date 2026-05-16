import 'dart:collection';
import 'dart:typed_data';

class PdfImageCacheManger {
  static final PdfImageCacheManger instance = PdfImageCacheManger._();
  PdfImageCacheManger._();
  factory PdfImageCacheManger() => instance;

  // Screen State ထဲမှာ အခုလို Map တစ်ခု ကြိုကြေညာထားပါမယ်
  // Key က pageIndex ဖြစ်ပြီး Value က ထွက်လာတဲ့ ပုံဖိုင် Bytes ဖြစ်ပါတယ်
  final LinkedHashMap<int, Uint8List> _renderedImagesCache =
      LinkedHashMap<int, Uint8List>();
  LinkedHashMap<int, Uint8List> get imageCache => _renderedImagesCache;

  int get cacheCount => _renderedImagesCache.length;

  int get maxCount => 50;

  int get cacheSize {
    int size = 0;
    for (var data in _renderedImagesCache.values) {
      size += data.length;
    }
    return size;
  }

  void clear() {
    _renderedImagesCache.clear();
  }

  void setCache(int key, Uint8List data) {
    if (_renderedImagesCache.containsKey(key)) {
      _renderedImagesCache.remove(key);
    }

    if (_renderedImagesCache.length >= maxCount) {
      final oldKey = _renderedImagesCache.keys.first;
      _renderedImagesCache.remove(oldKey);
    }

    _renderedImagesCache[key] = data;
  }

  Uint8List? getCache(int key) {
    if (!_renderedImagesCache.containsKey(key)) return null;

    // သူ့ကို အသစ်ဆုံး အနေအထား ဖြစ်သွားအောင် ရှေ့ကနေ နောက်ဆုံးကို ပို့ပေးခြင်း
    final data = _renderedImagesCache.remove(key)!;
    _renderedImagesCache[key] = data;

    return data;
  }
}
