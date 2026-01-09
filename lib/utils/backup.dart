abstract class Backup {
  final DateTime createdAt;

  Backup({required this.createdAt});
}

class LocalBackup extends Backup {
  final String filepath;

  LocalBackup({required super.createdAt, required this.filepath});
}

class GoogleDriveBackup extends Backup {
  final String fileId;

  GoogleDriveBackup({required super.createdAt, required this.fileId});
}
