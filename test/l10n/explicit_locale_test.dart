// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app language reaches text only as an explicit `AppLocalizations` (or its
/// `localeName`). Anything that reads `Intl.defaultLocale` instead is not rebuilt
/// by a language switch, because no widget depends on it.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.dart') && !path.endsWith('.g.dart') && !path.startsWith('lib/l10n/app_localizations'))
      .toList()
    ..sort();

  List<String> scan(void Function(String path, CompilationUnit unit, List<String> found) visit) {
    final found = <String>[];
    for (final path in files) {
      final result = parseFile(path: File(path).absolute.path, featureSet: FeatureSet.latestLanguageVersion());
      visit(path, result.unit, found);
    }
    return found;
  }

  test('every DateFormat and NumberFormat names its locale', () {
    final found = scan((path, unit, found) {
      unit.accept(_FormatterVisitor(path, unit, found));
    });
    expect(found, isEmpty, reason: 'Pass l10n.localeName:\n${found.join('\n')}');
  });

  test('nothing but the app shell touches the default locale', () {
    final found = scan((path, unit, found) {
      if (path != 'lib/main.dart') unit.accept(_DefaultLocaleVisitor(path, unit, found));
    });
    expect(found, isEmpty, reason: 'Take an AppLocalizations parameter instead:\n${found.join('\n')}');
  });

  test('models do not depend on the app language', () {
    final found = scan((path, unit, found) {
      if (!path.startsWith('lib/models/')) return;
      for (final directive in unit.directives.whereType<ImportDirective>()) {
        final uri = directive.uri.stringValue ?? '';
        if (uri.contains('l10n/')) found.add('$path: $uri');
      }
    });
    expect(found, isEmpty, reason: 'Move the text into a lib/l10n/ extension:\n${found.join('\n')}');
  });
}

String _location(String path, CompilationUnit unit, AstNode node) =>
    '$path:${unit.lineInfo.getLocation(node.offset).lineNumber}  ${node.toSource()}';

class _FormatterVisitor extends RecursiveAstVisitor<void> {
  _FormatterVisitor(this.path, this.unit, this.found);

  final String path;
  final CompilationUnit unit;
  final List<String> found;

  static const _formatters = {'DateFormat', 'NumberFormat'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target == null && _formatters.contains(node.methodName.name)) {
      _check(node, node.argumentList, unnamed: true);
    } else if (target is SimpleIdentifier && _formatters.contains(target.name)) {
      _check(node, node.argumentList, unnamed: false);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName;
    if (_formatters.contains(name.type.name.lexeme)) _check(node, node.argumentList, unnamed: name.name == null);
    super.visitInstanceCreationExpression(node);
  }

  /// `DateFormat(pattern, locale)` and `NumberFormat(pattern, locale)` take it
  /// second; the named constructors take it first or as `locale:`.
  void _check(AstNode node, ArgumentList args, {required bool unnamed}) {
    final positional = args.arguments.where((a) => a is! NamedArgument).length;
    final named = args.arguments.whereType<NamedArgument>().any((a) => a.name.lexeme == 'locale');
    final hasLocale = named || positional >= (unnamed ? 2 : 1);
    if (!hasLocale) found.add(_location(path, unit, node));
  }
}

class _DefaultLocaleVisitor extends RecursiveAstVisitor<void> {
  _DefaultLocaleVisitor(this.path, this.unit, this.found);

  final String path;
  final CompilationUnit unit;
  final List<String> found;

  static const _members = {'defaultLocale', 'getCurrentLocale', 'withLocale', 'systemLocale'};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'Intl' && _members.contains(node.identifier.name)) found.add(_location(path, unit, node));
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'Intl' && _members.contains(node.methodName.name)) {
      found.add(_location(path, unit, node));
    }
    super.visitMethodInvocation(node);
  }
}
