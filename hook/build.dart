import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

//linux tem path
///home/thancoder/Documents/pdfium-linux-x64/lib/libpdfium.so

//hook/build.dart -> file

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;

    final fileUri = await downloadBinaryUri(input);
    if (fileUri == null) return;

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

Future<Uri?> downloadBinaryUri(BuildInput input) async {
  Uri? fileUri;

  final targetOs = input.config.code.targetOS;
  final targetArchitecture = input.config.code.targetArchitecture;
  final packageName = input.packageName;

  final inputDir = Directory(
    input.packageRoot.resolve('.dart_tool'.join(packageName)).path,
  );
  if (!inputDir.existsSync()) {
    await inputDir.create(recursive: true);
  }
  final linuxInputDir = Directory(inputDir.path.join('linux'));
  final androidInputDir = Directory(inputDir.path.join('android'));

  // linux
  if (targetOs == OS.linux) {
    if (!linuxInputDir.existsSync()) {
      await linuxInputDir.create(recursive: true);
    }
    late String fileUrl;
    switch (targetArchitecture) {
      case Architecture.x64:
        fileUrl =
            'https://github.com/ThanCoder/t_pdf_core_engine/releases/download/pre.build-b-1/libpdfium-linux-x64.so';
        break;
      case Architecture.ia32:
        fileUrl =
            'https://github.com/ThanCoder/t_pdf_core_engine/releases/download/pre.build-b-1/pdfium-linux-x86.so';
        break;
    }

    fileUri = input.packageRoot.resolve(
      linuxInputDir.path.join('lib$packageName.so'),
    );
    await downloadUrl(fileUrl, fileUri.path);
  }
  // android
  else if (targetOs == OS.android) {
    fileUri = input.packageRoot.resolve(
      androidInputDir.path.join('lib$packageName.so'),
    );

    if (!androidInputDir.existsSync()) {
      await androidInputDir.create(recursive: true);
    }
    final archName = switch (targetArchitecture) {
      Architecture.arm => 'arm',
      Architecture.arm64 => 'arm64',
      Architecture.ia32 => 'x86',
      Architecture.x64 => 'x64',
      _ => throw ArgumentError('Unsupported architecture: $targetArchitecture'),
    };

    final fileUrl =
        'https://github.com/ThanCoder/t_pdf_core_engine/releases/download/pre.build-b-1/pdfium-android-$archName.so';
    fileUri = input.packageRoot.resolve(
      androidInputDir.path.join('lib$packageName.so'),
    );
    await downloadUrl(fileUrl, fileUri.path);
  } else {
    return null;
  }
  return fileUri;
}

Future<void> downloadUrl(String url, String outPath) async {
  final outFile = File(outPath);

  print('Downloading PDFium binary from: $downloadUrl');

  // 2. HttpClient အသုံးပြု၍ ဖိုင်ဒေါင်းလုဒ်ဆွဲခြင်း
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 200) {
      // Response stream ကို ဖိုင်ထဲသို့ တိုက်ရိုက် ရေးထည့်ခြင်း
      await response.pipe(outFile.openWrite());
      print('Download completed successfully: ${outFile.path}');
    } else {
      throw HttpException(
        'Failed to download file. Status code: ${response.statusCode}',
      );
    }
  } catch (e) {
    print('Error downloading PDFium: $e');
    rethrow;
  } finally {
    client.close();
  }
}
