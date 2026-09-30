import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/utils/attachment_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Attachment pdf(String id) => Attachment(id: id, extension: '.pdf', name: '$id.pdf');

  Setup setup(String id, DateTime datetime, List<Attachment> attachments) => Setup(
    id: id,
    tags: {},
    datetime: datetime.toUtc(),
    datetimeLocal: datetime,
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
    attachments: attachments,
  );

  Bike bike(String id, int orderIndex, List<Attachment> attachments) =>
      Bike(id: id, name: id, person: null, orderIndex: orderIndex, attachments: attachments);

  Component component(String id, int orderIndex, List<Attachment> attachments) => Component(
    id: id,
    name: id,
    componentType: ComponentType.fork,
    installations: [],
    adjustments: [],
    orderIndex: orderIndex,
    attachments: attachments,
  );

  List<String> ids(List<AttachmentIndexEntry> entries) => [for (final e in entries) e.attachment.id];

  group('attachmentIndex', () {
    test('lists setups newest first, then bikes and components by orderIndex', () {
      final entries = attachmentIndex(
        setups: [
          setup('old', DateTime(2024), [pdf('s-old')]),
          setup('new', DateTime(2025), [pdf('s-new-1'), pdf('s-new-2')]),
        ],
        bikes: [
          bike('b2', 1, [pdf('b2')]),
          bike('b1', 0, [pdf('b1')]),
        ],
        components: [
          component('c2', 1, [pdf('c2')]),
          component('c1', 0, [pdf('c1')]),
        ],
        trashedAttachments: [],
        filenames: [],
      );

      expect(ids(entries), ['s-new-1', 's-new-2', 's-old', 'b1', 'b2', 'c1', 'c2']);
      expect(entries.first.owner, (type: AttachmentOwnerType.setup, id: 'new'));
      expect(entries[3].owner, (type: AttachmentOwnerType.bike, id: 'b1'));
      expect(entries.last.owner, (type: AttachmentOwnerType.component, id: 'c2'));
    });

    test('appends unreferenced files as unlinked entries in folder order', () {
      final linked = pdf('linked');
      final entries = attachmentIndex(
        setups: [],
        bikes: [
          bike('b', 0, [linked]),
        ],
        components: [],
        trashedAttachments: [],
        filenames: ['zeta.jpg', linked.filename, 'alpha'],
      );

      expect(ids(entries), ['linked', 'zeta', 'alpha']);
      expect(entries[0].owner, isNotNull);
      expect(entries[1].owner, isNull);
      expect(entries[1].attachment.extension, '.jpg');
      expect(entries[1].attachment.name, 'zeta.jpg');
      expect(entries[2].attachment.extension, '');
    });

    test('hides files of trashed owners without counting them as unlinked', () {
      final trashed = pdf('trashed');
      final entries = attachmentIndex(
        setups: [],
        bikes: [],
        components: [],
        trashedAttachments: [trashed],
        filenames: [trashed.filename, 'orphan.pdf'],
      );

      expect(ids(entries), ['orphan']);
    });

    test('lists a file shared by several owners once, under the first', () {
      final shared = pdf('shared');
      final entries = attachmentIndex(
        setups: [
          setup('s', DateTime(2025), [shared]),
        ],
        bikes: [
          bike('b', 0, [shared]),
        ],
        components: [
          component('c', 0, [shared]),
        ],
        trashedAttachments: [],
        filenames: [shared.filename],
      );

      expect(entries, hasLength(1));
      expect(entries.single.owner, (type: AttachmentOwnerType.setup, id: 's'));
    });
  });
}
