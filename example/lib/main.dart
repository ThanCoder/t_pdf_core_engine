import 'package:flutter/material.dart';
import 'package:t_pdf_core_engine/t_pdf_core_engine.dart';
import 'package:t_pdf_core_engine/t_pdf_core_thumbnailer.dart';
import 'package:t_pdf_example/pdf_reader.dart';
import 'package:than_pkg/than_pkg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initTPdfNativeLibrary();

  runApp(MaterialApp(home: const MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('T PDF Native Lib')),
      body: Column(
        children: [
          ListTile(
            title: Text('Small Linux pdf'),
            onTap: () {
              context.go(
                builder: (context) =>
                    PdfReader(path: '/home/thancoder/Documents/test.pdf'),
              );
            },
          ),
          ListTile(
            title: Text('Big Linux pdf'),
            onTap: () {
              context.go(
                builder: (context) =>
                    PdfReader(path: '/home/thancoder/Documents/test2.pdf'),
              );
            },
          ),
          ListTile(
            title: Text('Small Android pdf'),
            onTap: () {
              context.go(
                builder: (context) =>
                    PdfReader(path: '/storage/emulated/0/test.pdf'),
              );
            },
          ),
          ListTile(
            title: Text('Big Android pdf'),
            onTap: () {
              context.go(
                builder: (context) =>
                    PdfReader(path: '/storage/emulated/0/test2.pdf'),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            if (!await ThanPkg.platform.isStoragePermissionGranted()) {
              await ThanPkg.platform.requestStoragePermission();
            }
            await TPdfCoreThumbnailer.extractImageAndSave(
              pageIndex: 1,
              '/home/thancoder/Documents/test2.pdf',
              savePath: 'out.png',
              overrideExistsImage: true,
            );
          } catch (e) {
            debugPrint(e.toString());
          }
        },
      ),
    );
  }
}

extension BuildContextExt on BuildContext {
  void go({required Widget Function(BuildContext context) builder}) {
    Navigator.push(this, MaterialPageRoute(builder: builder));
  }
}
