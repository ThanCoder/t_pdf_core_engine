import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

//linux tem path
///home/thancoder/Documents/pdfium-linux-x64/lib/libpdfium.so

//hook/build.dart -> file

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final targetOs = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    // ignore: prefer_typing_uninitialized_variables
    final inputDir = Directory(
      input.packageRoot.resolve('.dart_tool'.join(packageName)).path,
    );
    if (!inputDir.existsSync()) {
      await inputDir.create(recursive: true);
    }
    final linuxInputDir = Directory(inputDir.path.join('linux'));
    final androidInputDir = Directory(inputDir.path.join('android'));

    late Uri fileUri;
    // linux
    if (targetOs == OS.linux) {
      if (!linuxInputDir.existsSync()) {
        await linuxInputDir.create(recursive: true);
      }
      final linuxSourceFile = File(
        '/home/thancoder/Documents/pdfium-linux-x64/lib/libpdfium.so',
      );
      fileUri = input.packageRoot.resolve(
        linuxInputDir.path.join('lib$packageName.so'),
      );
      // copy
      await linuxSourceFile.copy(fileUri.path);
    }
    // android
    else if (targetOs == OS.android) {
      if (!androidInputDir.existsSync()) {
        await androidInputDir.create(recursive: true);
      }
      switch (targetArchitecture) {
        case Architecture.arm64:
          final sourceFile = File(
            '/home/thancoder/Documents/pdfium-android-arm64/lib/libpdfium.so',
          );
          fileUri = input.packageRoot.resolve(
            androidInputDir.path.join('lib${packageName}_android_arm64.so'),
          );
          await sourceFile.copy(fileUri.path);
          break;
      }
    } else {
      return;
    }

    output.assets.code.add(
      CodeAsset(
        package: packageName,
        name: '${packageName}_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: fileUri,
      ),
    );
    output.dependencies.add(fileUri);
  });
}

extension PathJoinExtension on String {
  String join(String name) {
    return '$this${Platform.pathSeparator}$name';
  }
}
