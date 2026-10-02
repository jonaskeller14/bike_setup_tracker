import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// The selectable getters hide draft entries; `resolve` reads the provenance
/// stored on a component (`Component.preset`) against the unfiltered catalog.

const _foxYaml = '''
brand: FOX
component_type: fork
nodes:
  - label: "36"
    level: model
    children:
      - label: Factory
        level: trim
      - label: Rhythm
        level: trim
        draft: true
  - label: "40"
    level: model
    draft: true
''';

const _ohlinsYaml = '''
brand: Öhlins
component_type: shock
nodes:
  - label: TTX22
    level: model
''';

ComponentCatalogRepository _repository() => ComponentCatalogRepository.withCatalogs([
  parseCatalogFile(_foxYaml),
  parseCatalogFile(_ohlinsYaml),
]);

void main() {
  group('forType', () {
    test('returns the non-draft products of that type', () async {
      final repository = _repository();

      expect((await repository.forType(ComponentType.fork)).map(presetDisplayName), ['FOX 36 Factory']);
      expect((await repository.forType(ComponentType.shock)).map(presetDisplayName), ['Öhlins TTX22']);
      expect(await repository.forType(ComponentType.stem), isEmpty);
    });

    test('caches the result', () async {
      final repository = _repository();

      expect(await repository.forType(ComponentType.fork), same(await repository.forType(ComponentType.fork)));
    });
  });

  test('all returns the non-draft products of every type', () async {
    expect((await _repository().all()).map(presetDisplayName), ['FOX 36 Factory', 'Öhlins TTX22']);
  });

  group('resolve', () {
    test('resolves a saved map to its product', () async {
      final resolved = await _repository().resolve(const {
        'brand': 'fox',
        'component_type': 'fork',
        'model': '36',
        'trim': 'factory',
      });

      expect(resolved?.product?.label, 'Factory');
    });

    test('still resolves an entry that went back to draft', () async {
      // `draft: true` hides a product from the picker, but a component saved
      // before that has to keep resolving its provenance.
      final repository = _repository();

      final trim = await repository.resolve(const {
        'brand': 'fox',
        'component_type': 'fork',
        'model': '36',
        'trim': 'rhythm',
      });
      final model = await repository.resolve(const {'brand': 'fox', 'component_type': 'fork', 'model': '40'});

      expect(trim?.product?.label, 'Rhythm');
      expect(model?.product?.label, '40');
    });

    test('returns null for a brand or type the catalog does not have', () async {
      final repository = _repository();

      expect(await repository.resolve(const {'brand': 'manitou', 'component_type': 'fork', 'model': '36'}), isNull);
      expect(await repository.resolve(const {'brand': 'fox', 'component_type': 'hovercraft'}), isNull);
      expect(await repository.resolve(const {}), isNull);
    });
  });

  group('asset bundle', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('discovers and parses the brand files of a type', () async {
      final repository = ComponentCatalogRepository();

      final forks = await repository.forType(ComponentType.fork);
      expect(forks, isNotEmpty);
      expect(forks.every((fork) => fork.catalog.componentType == ComponentType.fork), isTrue);
      expect(forks.any((fork) => fork.node.draft), isFalse);

      final shock = await repository.resolve(const {'brand': 'rst', 'component_type': 'shock', 'model': 'mono'});
      expect(shock?.node.draft, isTrue);
    });
  });
}
