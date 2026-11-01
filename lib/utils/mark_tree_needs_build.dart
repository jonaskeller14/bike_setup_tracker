import 'package:flutter/widgets.dart';

/// Marks [root] and every element below it dirty, so the next frame rebuilds
/// all of them. For a change that no widget depends on through an
/// `InheritedWidget`, such as `Intl.defaultLocale`.
void markTreeNeedsBuild(Element root) {
  void mark(Element element) {
    element.markNeedsBuild();
    element.visitChildren(mark);
  }

  mark(root);
}
