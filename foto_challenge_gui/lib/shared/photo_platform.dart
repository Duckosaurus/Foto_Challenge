import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_platform_io.dart'
    if (dart.library.html) 'photo_platform_web.dart';

/// Baut ein Image-Widget aus einem gespeicherten Foto-Ref (Pfad oder data-url).
Widget photoFromRef(String ref, {BoxFit fit = BoxFit.cover}) =>
    photoFromRefImpl(ref, fit: fit);

/// Wandelt ein ausgewähltes Foto in eine speicherbare Referenz um.
/// - Mobile/Desktop: file path
/// - Web: data-url (base64)
Future<String> refFromPickedXFile(XFile file) => refFromPickedXFileImpl(file);
