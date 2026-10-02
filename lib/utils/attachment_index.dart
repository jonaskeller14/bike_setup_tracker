import 'package:path/path.dart' as p;

import '../models/attachment.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/setup.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';

typedef AttachmentIndexEntry = ({Attachment attachment, AttachmentOwner? owner});

/// Setups newest first, then bikes and components by `orderIndex`, task rules
/// by name and task entries newest first, each with its attachments in owner
/// order, followed by the unlinked files among [filenames] in the given order.
/// A file referenced by several owners is listed once, under the first.
///
/// A trashed owner still owns its files, so [trashedAttachments] are neither
/// listed nor counted as unlinked until that owner is purged for good.
List<AttachmentIndexEntry> attachmentIndex({
  required Iterable<Setup> setups,
  required Iterable<Bike> bikes,
  required Iterable<Component> components,
  required Iterable<TaskRule> taskRules,
  required Iterable<TaskEntry> taskEntries,
  required Iterable<Attachment> trashedAttachments,
  required Iterable<String> filenames,
}) {
  final sortedSetups = setups.toList()..sort((a, b) => b.datetime.compareTo(a.datetime));
  final sortedBikes = bikes.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  final sortedComponents = components.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  final sortedTaskRules = taskRules.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final sortedTaskEntries = taskEntries.toList()..sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));

  final owned = <(AttachmentOwner, List<Attachment>)>[
    for (final setup in sortedSetups) ((type: AttachmentOwnerType.setup, id: setup.id), setup.attachments),
    for (final bike in sortedBikes) ((type: AttachmentOwnerType.bike, id: bike.id), bike.attachments),
    for (final component in sortedComponents)
      ((type: AttachmentOwnerType.component, id: component.id), component.attachments),
    for (final taskRule in sortedTaskRules)
      ((type: AttachmentOwnerType.taskRule, id: taskRule.id), taskRule.attachments),
    for (final taskEntry in sortedTaskEntries)
      ((type: AttachmentOwnerType.taskEntry, id: taskEntry.id), taskEntry.attachments),
  ];

  final entries = <AttachmentIndexEntry>[];
  final linked = <String>{};
  for (final (owner, attachments) in owned) {
    for (final attachment in attachments) {
      if (linked.add(attachment.filename)) entries.add((attachment: attachment, owner: owner));
    }
  }

  final trashed = trashedAttachments.map((a) => a.filename).toSet();
  for (final filename in filenames) {
    if (linked.contains(filename) || trashed.contains(filename)) continue;
    final attachment = Attachment(
      id: p.basenameWithoutExtension(filename),
      extension: p.extension(filename),
      name: filename,
    );
    entries.add((attachment: attachment, owner: null));
  }
  return entries;
}
