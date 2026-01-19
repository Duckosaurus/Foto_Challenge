import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CollageLayout { r1c3, r2c2, r2c3, r2c4, r3c3, r4c2, r4c4 }

extension CollageLayoutX on CollageLayout {
  int get rows => switch (this) {
    CollageLayout.r1c3 => 1,
    CollageLayout.r2c2 => 2,
    CollageLayout.r2c3 => 2,
    CollageLayout.r2c4 => 2,
    CollageLayout.r3c3 => 3,
    CollageLayout.r4c2 => 4,
    CollageLayout.r4c4 => 4,
  };

  int get cols => switch (this) {
    CollageLayout.r1c3 => 3,
    CollageLayout.r2c2 => 2,
    CollageLayout.r2c3 => 3,
    CollageLayout.r2c4 => 4,
    CollageLayout.r3c3 => 3,
    CollageLayout.r4c2 => 2,
    CollageLayout.r4c4 => 4,
  };

  String get label => switch (this) {
    CollageLayout.r1c3 => "1×3",
    CollageLayout.r2c2 => "2×2",
    CollageLayout.r2c3 => "2×3",
    CollageLayout.r2c4 => "2×4",
    CollageLayout.r3c3 => "3×3",
    CollageLayout.r4c2 => "4×2",
    CollageLayout.r4c4 => "4×4",
  };

  int get capacity => rows * cols;
  double get aspectRatio => cols / rows; // wichtig für korrektes Rendering
}

class CollageScreen extends StatefulWidget {
  final List<String> photoRefs; // file paths oder data:image... refs
  const CollageScreen({super.key, required this.photoRefs});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  static const double _radius = 12.0;

  Uint8List? _pngBytes;
  bool _generating = false;
  String? _error;
  CollageLayout _layout = CollageLayout.r3c3;

  List<ImageProvider?> _providers = [];

  @override
  void initState() {
    super.initState();

    final cap = _layout.capacity;
    final refs = widget.photoRefs.length > cap
        ? widget.photoRefs.sublist(widget.photoRefs.length - cap)
        : widget.photoRefs;

    _providers = refs.map(_providerFromRef).toList();
    _rebuildProvidersForLayout();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  ImageProvider? _providerFromRef(String ref) {
    try {
      if (kIsWeb) {
        if (ref.startsWith('data:image')) {
          final b64 = ref.split(',').last;
          return MemoryImage(base64Decode(b64));
        }
        return NetworkImage(ref);
      } else {
        if (ref.startsWith('data:image')) {
          final b64 = ref.split(',').last;
          return MemoryImage(base64Decode(b64));
        }
        return FileImage(File(ref));
      }
    } catch (_) {
      return null;
    }
  }

  void _rebuildProvidersForLayout() {
    final cap = _layout.capacity;
    final refs = widget.photoRefs.length > cap
        ? widget.photoRefs.sublist(widget.photoRefs.length - cap)
        : widget.photoRefs;

    _providers = refs.map(_providerFromRef).toList();
  }

  Widget _cell(ImageProvider? p) {
    if (p == null) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }
    return Image(image: p, fit: BoxFit.cover);
  }

  Future<RenderRepaintBoundary> _getPaintedBoundary() async {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) throw Exception("RepaintBoundary context fehlt.");

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception("RepaintBoundary RenderObject fehlt.");

    // WICHTIG: warten bis der Boundary wirklich painted ist
    // (sonst kommt dein '!debugNeedsPaint'-Assertion)
    int tries = 0;
    while (boundary.debugNeedsPaint && tries < 20) {
      tries++;
      await Future.delayed(const Duration(milliseconds: 30));
      await WidgetsBinding.instance.endOfFrame;
    }

    return boundary;
  }

  Future<void> _generate() async {
    if (_providers.whereType<ImageProvider>().length < 2) {
      setState(() {
        _error = "Für eine Kollage werden mindestens 2 Fotos benötigt.";
        _pngBytes = null;
        _generating = false;
      });
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _pngBytes = null;
    });

    try {
      // Bilder vorladen, damit Grid beim Capture nicht leer ist
      final toPrecache = _providers.whereType<ImageProvider>().toList();
      await Future.wait(toPrecache.map((p) => precacheImage(p, context)));

      // sicherstellen, dass nach dem precache nochmal ein Frame gerendert wurde
      await WidgetsBinding.instance.endOfFrame;

      final boundary = await _getPaintedBoundary();
      final uiImage = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Konnte PNG nicht erzeugen.");

      if (!mounted) return;
      setState(() {
        _pngBytes = byteData.buffer.asUint8List();
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cap = _layout.capacity;
    final cells = List<ImageProvider?>.from(_providers);
    while (cells.length < cap) {
      cells.add(null);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kollage"),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<CollageLayout>(
              value: _layout,
              items: CollageLayout.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                  .toList(),
              onChanged: _generating
                  ? null
                  : (v) async {
                if (v == null) return;
                setState(() {
                  _layout = v;
                  _pngBytes = null;
                  _error = null;
                  _rebuildProvidersForLayout();
                });
                await _generate();
              },
            ),
          ),
          IconButton(
            tooltip: "Neu erzeugen",
            icon: const Icon(Icons.refresh),
            onPressed: _generating ? null : _generate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: AspectRatio(
            aspectRatio: _layout.aspectRatio, // <<< dynamisch!
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius), // <<< außen immer rund
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // RepaintBoundary enthält Clip (damit PNG ebenfalls runde Ecken hat)
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_radius),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _layout.cols,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: cap,
                        itemBuilder: (_, i) => _cell(cells[i]),
                      ),
                    ),
                  ),

                  // PNG Preview ebenfalls im selben Clip-Bereich
                  if (_pngBytes != null)
                    Image.memory(
                      _pngBytes!,
                      fit: BoxFit.cover, // <<< verhindert “letterboxing”
                    ),

                  if (_generating)
                    const Center(child: CircularProgressIndicator()),

                  if (_error != null && !_generating)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: Text("Fehler: $_error"),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
