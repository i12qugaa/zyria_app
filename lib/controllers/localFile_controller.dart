import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'drive_controller.dart';

class LocalFileController {

  final DriveController _controller = DriveController();

  Future<void> importLocalZip(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        print("No se seleccionó ningún archivo ZIP.");
        return;
      }

      final file = File(result.files.single.path!);
      Uint8List zipBytes = await file.readAsBytes();

      bool ok = await _controller.restoreZipBackup(zipBytes, context);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restauración completada desde ZIP local.")),
        );
      }
    } catch (e) {
      print("Error al importar ZIP local: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al importar ZIP local: $e")),
      );
    }
  }
}
