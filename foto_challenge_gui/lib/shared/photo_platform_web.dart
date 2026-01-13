import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Widget photoFromRefImpl(String ref, {BoxFit fit = BoxFit.cover}) {
  if (ref.startsWith('data:image')) {
    final b64 = ref.split(',').last;
    final bytes = base64Decode(b64);
    return Image.memory(bytes, fit: fit);
  }
  return Image.network(ref, fit: fit);
}

Future<String> refFromPickedXFileImpl(XFile file) async {
  final bytes = await file.readAsBytes();
  final b64 = base64Encode(bytes);

  final name = file.name.toLowerCase();
  final mime = name.endsWith('.png') ? 'image/png' : 'image/jpeg';

  return 'data:$mime;base64,$b64';
}
