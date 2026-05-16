import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class RawThumbnailWidget extends StatelessWidget {
  final Uint8List rawBytes;
  final int width;
  final int height;

  const RawThumbnailWidget({
    super.key,
    required this.rawBytes,
    this.width = 80,
    this.height = 110,
  });

  // Raw BGRA bytes ကို Flutter က နားလည်တဲ့ ui.Image အဖြစ် ပြောင်းလဲပေးတဲ့အလုပ်
  Future<ui.Image> _loadRawImage() async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      rawBytes,
    );
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat:
          ui.PixelFormat.bgra8888, // 💡 PDFium ထွက်တဲ့ format အတိုင်း ကွက်တိ
    );

    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _loadRawImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return RawImage(
            image: snapshot.data,
            width: width.toDouble(),
            height: height.toDouble(),
            fit: BoxFit.fill,
            filterQuality: ui
                .FilterQuality
                .none, // 💡 ဒါက ပုံကို ပိုပြီး ဝါး/ကွဲ စေပါတယ် (Low quality fast render)
          );
        }
        return Container(
          width: width.toDouble(),
          height: height.toDouble(),
          color: Colors.grey[200],
        );
      },
    );
  }
}
