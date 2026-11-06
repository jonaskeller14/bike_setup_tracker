// ignore_for_file: depend_on_referenced_packages
// Lists user-facing string literals under lib/ that bypass the ARB files.
//
//   dart run tool/find_hardcoded_strings.dart
//
// It reads the syntax tree only (no type resolution), so it flags a literal by
// where it sits: the first argument of Text(...) and the value of a named
// argument such as labelText:, hintText: or tooltip:. Intentional literals go
// into tool/hardcoded_strings_allowlist.txt, one `path|literal|reason` per line.
// Exits with 1 when something is left over or an allowlist entry is stale.
//
// `--phrases` additionally lists every phrase-like literal (two or more words)
// the pattern check did not report. That list is for auditing helpers, models and
// services that return display text; it is long and needs a human to read it.
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

const _allowlistPath = 'tool/hardcoded_strings_allowlist.txt';

/// Named arguments whose string value is shown to the user: `title:`,
/// `labelText:`, `trueText:`, `tooltip:`, `semanticsLabel:` and the like.
final _textArgument = RegExp(
  r'^(text|title|subtitle|content|message|description|placeholder|tooltip|hint|caption|heading|body|label|'
  r'.*(Text|Label|Title|Tooltip|Message|Subtitle|Caption|Hint|Description))$',
);

/// Constructors and functions whose first positional string is shown to the user.
const _textCalls = {'Text', 'SelectableText', 'Tab', 'showAppSnackBar', 'TextSourceAttribution'};

typedef Finding = ({String path, int line, String literal, String context});

/// Calls whose arguments are never shown to the user.
const _silentCalls = {
  'debugPrint',
  'print',
  'log',
  'Exception',
  'StateError',
  'ArgumentError',
  'RangeError',
  'UnsupportedError',
  'UnimplementedError',
  'FormatException',
  'AssertionError',
  'RegExp',
  'DateFormat',
  'Uri',
  'parse',
  'tryParse',
};

class _Collector extends RecursiveAstVisitor<void> {
  _Collector(this.path, this.lineInfo, this.findings, this.phrases);

  final String path;
  final LineInfo lineInfo;
  final List<Finding> findings;
  final List<Finding> phrases;
  final _reported = <int>{};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkCall(node.constructorName.type.name.lexeme, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    _checkCall(node.methodName.name, node.argumentList, target: target is SimpleIdentifier ? target.name : null);
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _checkPhrase(node);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _checkPhrase(node);
    super.visitStringInterpolation(node);
  }

  void _checkPhrase(StringLiteral literal) {
    if (_reported.contains(literal.offset) || literal.parent is StringInterpolation) return;
    final text = _literalText(literal);
    if (!RegExp(r'[A-Za-z]{2,}[ ]+[A-Za-z]{2,}').hasMatch(text)) return;
    for (AstNode? node = literal.parent; node != null; node = node.parent) {
      if (node is Directive || node is Annotation || node is AssertStatement) return;
      if (node is InstanceCreationExpression && _silentCalls.contains(node.constructorName.type.name.lexeme)) return;
      if (node is MethodInvocation && _silentCalls.contains(node.methodName.name)) return;
      if (node is ThrowExpression) return;
    }
    phrases.add((path: path, line: lineInfo.getLocation(literal.offset).lineNumber, literal: text, context: 'phrase'));
  }

  void _checkCall(String callee, ArgumentList args, {String? target}) {
    final snackBar = target == 'AppSnackBar';
    for (final argument in args.arguments) {
      if (snackBar && argument is! NamedArgument && argument != args.arguments.first) {
        _checkExpression(argument.argumentExpression, 'AppSnackBar.$callee(...)');
        continue;
      }
      if (argument is NamedArgument) {
        final name = argument.name.lexeme;
        if (name != 'debugLabel' && _textArgument.hasMatch(name)) {
          _checkExpression(argument.argumentExpression, '$name:');
        }
      } else if (_textCalls.contains(callee) && argument == args.arguments.first) {
        _checkExpression(argument.argumentExpression, '$callee(...)');
      }
    }
  }

  void _checkExpression(Expression expression, String context) {
    switch (expression) {
      case StringLiteral():
        _report(expression, context);
      case ConditionalExpression():
        _checkExpression(expression.thenExpression, context);
        _checkExpression(expression.elseExpression, context);
      case ParenthesizedExpression():
        _checkExpression(expression.expression, context);
      case BinaryExpression() when expression.operator.lexeme == '+':
        _checkExpression(expression.leftOperand, context);
        _checkExpression(expression.rightOperand, context);
      default:
    }
  }

  void _report(StringLiteral literal, String context) {
    _reported.add(literal.offset);
    final text = _literalText(literal);
    if (!RegExp(r'[A-Za-z]{2}').hasMatch(text)) return;
    findings.add((
      path: path,
      line: lineInfo.getLocation(literal.offset).lineNumber,
      literal: text,
      context: context,
    ));
  }

  /// The fixed parts of the literal, with each interpolation shown as `$…`.
  String _literalText(StringLiteral literal) => switch (literal) {
    SimpleStringLiteral() => literal.value,
    AdjacentStrings() => literal.strings.map(_literalText).join(),
    StringInterpolation() => literal.elements.map((e) => e is InterpolationString ? e.value : r'$…').join(),
  };
}

Map<String, String> _readAllowlist() {
  final file = File(_allowlistPath);
  if (!file.existsSync()) return {};
  final entries = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('|');
    if (parts.length < 3) {
      stderr.writeln('Bad allowlist line (want path|literal|reason): $line');
      exit(2);
    }
    // The reason is the last field, so a literal may contain a `|`.
    entries['${parts.first}|${parts.sublist(1, parts.length - 1).join('|')}'] = parts.last;
  }
  return entries;
}

bool _isScanned(String path) =>
    path.endsWith('.dart') &&
    !path.endsWith('.g.dart') &&
    !path.startsWith('lib/l10n/') &&
    !path.startsWith('lib/database/') &&
    !path.startsWith('lib/env/');

void main(List<String> arguments) {
  final findings = <Finding>[];
  final phrases = <Finding>[];
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where(_isScanned)
          .toList()
        ..sort();
  for (final path in files) {
    final result = parseFile(path: File(path).absolute.path, featureSet: FeatureSet.latestLanguageVersion());
    result.unit.accept(_Collector(path, result.lineInfo, findings, phrases));
  }

  if (arguments.contains('--phrases')) {
    final reported = {for (final f in findings) '${f.path}:${f.line}:${f.literal}'};
    for (final f in phrases) {
      if (!reported.contains('${f.path}:${f.line}:${f.literal}')) stdout.writeln('${f.path}:${f.line}  "${f.literal}"');
    }
    return;
  }

  final allowlist = _readAllowlist();
  final used = <String>{};
  final remaining = <Finding>[];
  for (final finding in findings) {
    final key = '${finding.path}|${finding.literal}';
    if (allowlist.containsKey(key)) {
      used.add(key);
    } else {
      remaining.add(finding);
    }
  }
  final stale = allowlist.keys.where((key) => !used.contains(key)).toList();

  for (final f in remaining) {
    stdout.writeln('${f.path}:${f.line}  ${f.context}  "${f.literal}"');
  }
  for (final key in stale) {
    stdout.writeln('stale allowlist entry: $key');
  }
  stdout.writeln(
    '${remaining.length} finding(s), ${stale.length} stale allowlist entr${stale.length == 1 ? 'y' : 'ies'}, '
    '${used.length} allowlisted.',
  );
  if (remaining.isNotEmpty || stale.isNotEmpty) exit(1);
}
