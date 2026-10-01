import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum AttachmentOwnerType { setup, bike, component }

typedef AttachmentOwner = ({AttachmentOwnerType type, String id});

class Attachment {
  final String id;
  final String extension; // original, lower-cased, with leading dot ('.pdf') or ''
  final String name;

  static const Set<String> imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
    '.bmp',
  };

  Attachment({String? id, required String extension, required this.name})
    : id = id ?? const Uuid().v4(),
      extension = extension.toLowerCase();

  String get filename => '$id$extension';

  bool get isImage => imageExtensions.contains(extension);

  IconData get iconData => extension == '.pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined;

  String get exportFileName {
    final illegalFileNameChars = RegExp(r'[/\\:*?"<>|]');
    final base = (name.trim().isEmpty ? filename : name.trim()).replaceAll(
      illegalFileNameChars,
      '_',
    );
    if (extension.isEmpty || base.toLowerCase().endsWith(extension)) {
      return base;
    }
    return '$base$extension';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'extension': extension,
    'name': name,
  };

  /// Ids and extensions arrive from imported JSON, so a filename must never be able to
  /// point outside the attachments folder.
  static bool isPlainFilename(String filename) =>
      filename != '.' && filename != '..' && !filename.contains(RegExp(r'[/\\]'));

  factory Attachment.fromJson(Map<String, dynamic> json) {
    final attachment = Attachment(
      id: json['id'] as String,
      extension: json['extension'] as String,
      name: json['name'] as String,
    );
    if (!isPlainFilename(attachment.filename)) {
      throw FormatException('Attachment "${attachment.filename}" is not a plain file name.');
    }
    return attachment;
  }

  /// Returns null instead of throwing when [json] is not a valid attachment.
  static Attachment? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final extension = json['extension'];
    final name = json['name'];
    if (id is! String || extension is! String || name is! String) return null;
    if (id.isEmpty) return null;
    final attachment = Attachment(id: id, extension: extension, name: name);
    return isPlainFilename(attachment.filename) ? attachment : null;
  }

  Attachment copyWith({
    Object? id = const _Sentinel(),
    Object? extension = const _Sentinel(),
    Object? name = const _Sentinel(),
  }) {
    return Attachment(
      id: id is _Sentinel ? this.id : (id as String),
      extension: extension is _Sentinel ? this.extension : (extension as String),
      name: name is _Sentinel ? this.name : (name as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Attachment && id == other.id && extension == other.extension && name == other.name;
  }

  @override
  int get hashCode => Object.hash(id, extension, name);
}

class _Sentinel {
  const _Sentinel();
}
