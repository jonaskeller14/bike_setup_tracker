import 'dart:convert';
import 'dart:io';

import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/catalog_revisions.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guards the adjusters a component built from the catalog has.
///
/// `data/component_presets/adjusters.lock` holds each brand file's revision
/// (`fork/fox#revision=2`) and a signature of the adjusters a rider gets per
/// product and choice of every required axis
/// (`fork/fox/36/2025/factory#damper=grip_x2 <hash>`). A changed signature fails
/// here unless a `changes:` entry newer than the locked revision covers that
/// product, so components built before the change are told about it.
///
/// `UPDATE_CATALOG_ADJUSTERS=1 flutter test test/component_catalog_adjusters_test.dart`
/// updates the lockfile, and refuses to while a change has no revision. The
/// lockfile is append-only: a line is added or its hash updated, never
/// dropped, so a product that comes back is checked against its old adjusters.
void main() {
  final catalogDir = Directory(p.join(Directory.current.path, 'data', 'component_presets'));
  final lockFile = File(p.join(catalogDir.path, 'adjusters.lock'));

  final current = _collect(catalogDir);
  final locked = lockFile.existsSync() ? _Lock.parse(lockFile.readAsLinesSync()) : null;

  if (Platform.environment['UPDATE_CATALOG_ADJUSTERS'] == '1') {
    test('updates adjusters.lock', () {
      if (locked != null) expect(_unrevisioned(current, locked), isEmpty, reason: _unrevisionedReason);
      lockFile.writeAsStringSync('${_lines(current, locked).join('\n')}\n');
    });
    return;
  }

  test('built adjusters change only with a catalog revision', () {
    expect(locked, isNotNull, reason: 'missing adjusters.lock — run with UPDATE_CATALOG_ADJUSTERS=1');
    expect(_unrevisioned(current, locked!), isEmpty, reason: _unrevisionedReason);
  });

  test('adjusters.lock is up to date', () {
    expect(locked, isNotNull, reason: 'missing adjusters.lock — run with UPDATE_CATALOG_ADJUSTERS=1');
    expect(_stale(current, locked!), isEmpty, reason: 'Regenerate with UPDATE_CATALOG_ADJUSTERS=1.');
  });
}

const _unrevisionedReason =
    'The adjusters of these products changed without a catalog revision. Bump the brand file\'s `revision:` '
    'and append a `changes:` entry (`fix` or `review`) whose `when:` covers them, see SCHEMA.md.';

class _Signature {
  final String hash;
  final ResolvedPreset resolved;

  const _Signature(this.hash, this.resolved);
}

class _Current {
  /// Brand path (`fork/fox`) → revision.
  final Map<String, int> revisions;
  final Map<String, _Signature> signatures;

  const _Current(this.revisions, this.signatures);
}

/// The lockfile for [current], keeping the [locked] lines it no longer has.
List<String> _lines(_Current current, _Lock? locked) => [
  for (final MapEntry(:key, :value) in {...?locked?.revisions, ...current.revisions}.entries) '$key#revision=$value',
  for (final MapEntry(:key, :value) in {
    ...?locked?.hashes,
    for (final MapEntry(:key, :value) in current.signatures.entries) key: value.hash,
  }.entries)
    '$key $value',
]..sort();

class _Lock {
  final Map<String, int> revisions;
  final Map<String, String> hashes;

  const _Lock(this.revisions, this.hashes);

  factory _Lock.parse(List<String> lines) {
    final revisions = <String, int>{};
    final hashes = <String, String>{};
    for (final line in lines.where((line) => line.isNotEmpty)) {
      final revision = RegExp(r'^(\S+)#revision=(\d+)$').firstMatch(line);
      if (revision != null) {
        revisions[revision[1]!] = int.parse(revision[2]!);
      } else {
        final [key, hash] = line.split(' ');
        hashes[key] = hash;
      }
    }
    return _Lock(revisions, hashes);
  }
}

/// Locked products whose adjusters changed with no newer change covering them,
/// and brand files whose revision went down.
List<String> _unrevisioned(_Current current, _Lock locked) => [
  for (final MapEntry(:key, :value) in current.revisions.entries)
    if (value < (locked.revisions[key] ?? 1)) '$key: revision went down from ${locked.revisions[key]} to $value',
  for (final MapEntry(:key, value: hash) in locked.hashes.entries)
    if (current.signatures[key] case final signature? when signature.hash != hash)
      if (!signature.resolved.catalog.changes.any(
        (change) =>
            change.revision > (locked.revisions[_brandPath(key)] ?? 1) &&
            catalogChangeApplies(change, signature.resolved),
      ))
        key,
];

List<String> _stale(_Current current, _Lock locked) => [
  for (final MapEntry(:key, :value) in current.revisions.entries)
    if (locked.revisions[key] != value) '$key: revision $value, locked ${locked.revisions[key]}',
  for (final MapEntry(:key, :value) in current.signatures.entries)
    if (locked.hashes[key] != value.hash) locked.hashes.containsKey(key) ? '$key: changed' : '$key: not locked',
];

String _brandPath(String key) => key.split('/').take(2).join('/');

_Current _collect(Directory catalogDir) {
  final files = catalogDir.listSync(recursive: true).whereType<File>().where((f) => p.extension(f.path) == '.yaml');
  final revisions = <String, int>{};
  final signatures = <String, _Signature>{};

  for (final file in files) {
    final catalog = parseCatalogFile(file.readAsStringSync());
    final brandPath = '${catalog.componentType.name}/${catalog.id}';
    revisions[brandPath] = catalog.revision;
    for (final product in catalogProducts(catalog)) {
      for (final resolved in _requiredChoices(product)) {
        final key = [
          [brandPath, for (final node in resolved.path) node.id].join('/'),
          for (final axis in resolved.axes)
            if (axis.required) '${axis.id}=${_valueId(resolved.selections[axis.id]!.id)}',
        ].join('#');
        signatures[key] = _Signature(_signature(resolved), resolved);
      }
    }
  }
  return _Current(revisions, signatures);
}

/// [product] with each combination of values of its required axes chosen.
List<ResolvedPreset> _requiredChoices(ResolvedPreset product) {
  var choices = [product];
  for (final axis in product.axes.where((axis) => axis.required)) {
    choices = [
      for (final choice in choices)
        for (final value in axis.values) choice.select(axis, value),
    ];
  }
  return choices;
}

/// What the catalog builds for [resolved], every field included; the SAG
/// adjuster is the app's, not the catalog's.
String _signature(ResolvedPreset resolved) {
  final adjustments = [
    for (final spec in [
      ...resolved.product!.adjustments,
      for (final value in resolved.selections.values) ...value.adjustments,
    ])
      spec.build().toJson()..remove('id'),
  ];
  return sha1.convert(utf8.encode(jsonEncode(adjustments))).toString().substring(0, 12);
}

String _valueId(Object id) => id is num ? formatSpecNumber(id) : '$id';
