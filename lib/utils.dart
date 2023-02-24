import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

Future<File> cropImage(XFile pickedFile) async {
  // Crop image here
  final File? croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    cropStyle: CropStyle.rectangle,
    aspectRatioPresets: [
      CropAspectRatioPreset.square,
      // CropAspectRatioPreset.ratio3x2,
      // CropAspectRatioPreset.original,
      // CropAspectRatioPreset.ratio4x3,
      // CropAspectRatioPreset.ratio16x9
    ],
    // ignore: prefer_const_constructors
    androidUiSettings: AndroidUiSettings(
        toolbarTitle: 'Cropper',
        toolbarColor: Colors.blue, //Theme.of(context).primaryColor,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false),
    iosUiSettings: const IOSUiSettings(
      minimumAspectRatio: 1.0,
    ),
  );

  return croppedFile!;
}

Future<File> getImage(String url) async {
  /// Get Image from server
  final Response res = await Dio().get<List<int>>(
    url,
    options: Options(
      responseType: ResponseType.bytes,
    ),
  );

  /// Get App local storage
  final Directory appDir = await getApplicationDocumentsDirectory();

  /// Generate Image Name
  final String imageName = url.split('/').last;

  /// Create Empty File in app dir & fill with new image
  final File file = File(join(appDir.path, imageName));

  file.writeAsBytesSync(res.data as List<int>);

  return file;
}

// Reading bytes from a network image
Future<Uint8List> readNetworkImage(String imageUrl) async {
  final ByteData data =
      await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
  final Uint8List bytes = data.buffer.asUint8List();
  return bytes;
}
