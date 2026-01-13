import 'dart:io';
import 'package:flutter/widgets.dart';

import 'package:image_picker/image_picker.dart';

Widget photoFromRefImpl(String ref, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(ref), fit: fit);
}

Future<String> refFromPickedXFileImpl(XFile file) async {
  return file.path;
}
