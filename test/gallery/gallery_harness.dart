// Shared plumbing for the widget galleries in test/gallery/: fonts, screenshots
// and the one-page overview. A gallery file supplies the states; see
// installation_parent_gallery_test.dart for the pattern.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const galleryPixelRatio = 1.5;

/// (name, theme, overview background, overview text) of each rendered theme.
final galleryThemes = [
  ('light', materialAppTheme, const Color(0xFFE6E6E6), const Color(0xFF111111)),
  ('dark', materialAppDarkTheme, const Color(0xFF0B0B0B), const Color(0xFFEEEEEE)),
];

/// Loads the fonts and returns the empty output directory
/// `build/gallery/<name>/` (git-ignored). Call from `setUpAll`.
Future<Directory> prepareGallery(String name) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  final output = Directory('build/gallery/$name')..createSync(recursive: true);
  for (final file in output.listSync().whereType<File>().where((f) => f.path.endsWith('.png'))) {
    file.deleteSync();
  }
  return output;
}

/// Without these, flutter_test draws text as boxes (the Ahem font) and icons
/// as empty squares, since galleries run outside the app's asset bundle.
Future<void> _loadFonts() async {
  Directory? materialFonts;
  for (var dir = File(Platform.resolvedExecutable).parent; dir.parent.path != dir.path; dir = dir.parent) {
    final candidate = Directory('${dir.path}${Platform.pathSeparator}material_fonts');
    if (candidate.existsSync()) {
      materialFonts = candidate;
      break;
    }
  }

  Future<void> load(String family, Iterable<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  if (materialFonts != null) {
    final dir = materialFonts.path + Platform.pathSeparator;
    await load('Roboto', [for (final w in ['light', 'regular', 'medium', 'bold']) '${dir}roboto-$w.ttf']);
    await load('MaterialIcons', ['${dir}materialicons-regular.otf']);
  }
  await load('BikeIcons', ['assets/fonts/BikeIcons.ttf']);
}

/// Collects the screenshots of one theme and writes them, plus the overview.
class GallerySession {
  GallerySession(this.tester, this.output, {required this.themeName, required this.background, required this.textColor});

  final WidgetTester tester;
  final Directory output;
  final String themeName;
  final Color background;
  final Color textColor;
  final _shots = <_Shot>[];

  /// Captures [boundary] (optionally cropped to [crop], in logical pixels).
  Future<void> add(String slug, String title, RenderRepaintBoundary boundary, {Rect? crop}) async {
    final image = await tester.runAsync(() => _capture(boundary, crop: crop));
    _shots.add(_Shot(title, image!));
    await tester.runAsync(() => _writePng(image, '${slug}_$themeName'));
  }

  Future<void> finish() async {
    final overview = await tester.runAsync(() => _compose(_shots, background, textColor));
    await tester.runAsync(() => _writePng(overview!, 'overview_$themeName'));
    for (final shot in _shots) {
      shot.image.dispose();
    }
    overview!.dispose();
    // ignore: avoid_print
    print('Wrote ${output.absolute.path}${Platform.pathSeparator}overview_$themeName.png');
  }

  Future<void> _writePng(ui.Image image, String name) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  }
}

class _Shot {
  final String title;
  final ui.Image image;

  const _Shot(this.title, this.image);
}

Future<ui.Image> _capture(RenderRepaintBoundary boundary, {Rect? crop}) async {
  final full = await boundary.toImage(pixelRatio: galleryPixelRatio);
  if (crop == null) return full;
  final width = (crop.width * galleryPixelRatio).round();
  final height = (crop.height * galleryPixelRatio).round();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    full,
    Rect.fromLTWH(crop.left * galleryPixelRatio, crop.top * galleryPixelRatio, width.toDouble(), height.toDouble()),
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint(),
  );
  final cropped = await recorder.endRecording().toImage(width, height);
  full.dispose();
  return cropped;
}

/// Packs the screenshots, in order, into columns as tall as the tallest one.
Future<ui.Image> _compose(List<_Shot> shots, Color background, Color textColor) async {
  const gap = 36;
  const titleHeight = 56;

  final columnHeight = shots.map((s) => s.image.height).reduce((a, b) => a > b ? a : b) + titleHeight + gap;
  final columns = <List<_Shot>>[];
  var current = <_Shot>[];
  var used = 0;
  for (final shot in shots) {
    final height = titleHeight + shot.image.height + gap;
    if (current.isNotEmpty && used + height > columnHeight) {
      columns.add(current);
      current = [];
      used = 0;
    }
    current.add(shot);
    used += height;
  }
  if (current.isNotEmpty) columns.add(current);

  int widthOf(List<_Shot> column) => column.map((s) => s.image.width).reduce((a, b) => a > b ? a : b);
  int heightOf(List<_Shot> column) => column.fold(0, (sum, s) => sum + titleHeight + s.image.height + gap);

  final width = columns.fold(gap, (sum, c) => sum + widthOf(c) + gap);
  final height = columns.map(heightOf).reduce((a, b) => a > b ? a : b) + gap;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = background);
  var x = gap.toDouble();
  for (final column in columns) {
    var y = gap.toDouble();
    for (final shot in column) {
      TextPainter(
        text: TextSpan(
          text: shot.title,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )
        ..layout(maxWidth: widthOf(column).toDouble())
        ..paint(canvas, Offset(x, y));
      canvas.drawImage(shot.image, Offset(x, y + titleHeight), Paint());
      y += titleHeight + shot.image.height + gap;
    }
    x += widthOf(column) + gap;
  }
  return recorder.endRecording().toImage(width, height);
}
