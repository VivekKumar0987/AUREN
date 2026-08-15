import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

enum RevealedStatus {
  active,
  rejected,
  completed;

  static RevealedStatus fromStorage(String value) {
    return RevealedStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RevealedStatus.active,
    );
  }
}

class RevealedExperienceRecord {
  const RevealedExperienceRecord({
    required this.experienceId,
    required this.revealedAt,
    required this.localDate,
    required this.replacementIndex,
    required this.status,
  });

  final String experienceId;
  final DateTime revealedAt;
  final String localDate;
  final int replacementIndex;
  final RevealedStatus status;

  factory RevealedExperienceRecord.fromRow(Map<String, Object?> row) {
    return RevealedExperienceRecord(
      experienceId: row['experience_id'] as String,
      revealedAt: DateTime.parse(row['revealed_at'] as String),
      localDate: row['local_date'] as String,
      replacementIndex: row['replacement_index'] as int,
      status: RevealedStatus.fromStorage(row['status'] as String),
    );
  }

  Map<String, Object?> toBackupJson() {
    return {
      'experience_id': experienceId,
      'revealed_at': revealedAt.toIso8601String(),
      'local_date': localDate,
      'replacement_index': replacementIndex,
      'status': status.name,
    };
  }
}

class ReflectionRecord {
  const ReflectionRecord({
    required this.experienceId,
    required this.wouldHaveDoneWithoutAuren,
    required this.worthTime,
    required this.note,
    required this.createdAt,
  });

  final String experienceId;
  final bool wouldHaveDoneWithoutAuren;
  final bool worthTime;
  final String note;
  final DateTime createdAt;

  factory ReflectionRecord.fromRow(Map<String, Object?> row) {
    return ReflectionRecord(
      experienceId: row['experience_id'] as String,
      wouldHaveDoneWithoutAuren:
          (row['would_have_done_without_auren'] as int) == 1,
      worthTime: (row['worth_time'] as int) == 1,
      note: (row['note'] as String?) ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, Object?> toBackupJson() {
    return {
      'experience_id': experienceId,
      'would_have_done_without_auren': wouldHaveDoneWithoutAuren,
      'worth_time': worthTime,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AurenUserData {
  const AurenUserData({
    required this.revealed,
    required this.reflections,
    required this.settings,
  });

  final List<Map<String, Object?>> revealed;
  final List<Map<String, Object?>> reflections;
  final Map<String, String> settings;

  Map<String, Object?> toJson() {
    return {
      'revealed': revealed,
      'reflections': reflections,
      'settings': settings,
    };
  }

  factory AurenUserData.fromJson(Map<String, Object?> json) {
    final settings = <String, String>{};
    final rawSettings = json['settings'];
    if (rawSettings is Map) {
      for (final entry in rawSettings.entries) {
        settings[entry.key.toString()] = entry.value.toString();
      }
    }

    return AurenUserData(
      revealed: _readRows(json['revealed']),
      reflections: _readRows(json['reflections']),
      settings: settings,
    );
  }

  static List<Map<String, Object?>> _readRows(Object? value) {
    if (value is! List) {
      return const <Map<String, Object?>>[];
    }
    return value
        .whereType<Map>()
        .map((row) => row.cast<String, Object?>())
        .toList(growable: false);
  }
}

class AurenDatabase {
  AurenDatabase({DatabaseFactory? databaseFactory, String? databasePath})
    : _databaseFactoryOverride = databaseFactory,
      _databasePathOverride = databasePath;

  final DatabaseFactory? _databaseFactoryOverride;
  final String? _databasePathOverride;
  Database? _database;

  Future<void> open() async {
    _database ??= await _openDatabase();
  }

  Future<Database> get _db async {
    await open();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final factory = _databaseFactoryOverride ?? _defaultDatabaseFactory();
    final dbPath = _databasePathOverride ?? await _defaultDatabasePath();

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE revealed_experiences (
  experience_id TEXT PRIMARY KEY,
  revealed_at TEXT NOT NULL,
  local_date TEXT NOT NULL,
  replacement_index INTEGER NOT NULL,
  status TEXT NOT NULL
)
''');
          await db.execute('''
CREATE INDEX idx_revealed_local_date
ON revealed_experiences(local_date)
''');
          await db.execute('''
CREATE TABLE reflections (
  experience_id TEXT PRIMARY KEY,
  would_have_done_without_auren INTEGER NOT NULL,
  worth_time INTEGER NOT NULL,
  note TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
          await db.execute('''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
        },
      ),
    );
  }

  DatabaseFactory _defaultDatabaseFactory() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  Future<String> _defaultDatabasePath() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      return p.join(dir.path, 'auren.db');
    }
    return p.join(await sqflite.getDatabasesPath(), 'auren.db');
  }

  Future<List<String>> revealedExperienceIds() async {
    final rows = await (await _db).query(
      'revealed_experiences',
      columns: ['experience_id'],
      orderBy: 'revealed_at DESC',
    );
    return rows.map((row) => row['experience_id'] as String).toList();
  }

  Future<List<RevealedExperienceRecord>> revealedForDate(
    String localDate,
  ) async {
    final rows = await (await _db).query(
      'revealed_experiences',
      where: 'local_date = ?',
      whereArgs: [localDate],
      orderBy: 'replacement_index ASC',
    );
    return rows.map(RevealedExperienceRecord.fromRow).toList();
  }

  Future<List<RevealedExperienceRecord>> recentRevealed({int limit = 8}) async {
    final rows = await (await _db).query(
      'revealed_experiences',
      orderBy: 'revealed_at DESC',
      limit: limit,
    );
    return rows.map(RevealedExperienceRecord.fromRow).toList();
  }

  Future<List<ReflectionRecord>> reflections() async {
    final rows = await (await _db).query(
      'reflections',
      orderBy: 'created_at DESC',
    );
    return rows.map(ReflectionRecord.fromRow).toList();
  }

  Future<void> revealExperience({
    required String experienceId,
    required DateTime revealedAt,
    required String localDate,
    required int replacementIndex,
  }) async {
    await (await _db).insert('revealed_experiences', {
      'experience_id': experienceId,
      'revealed_at': revealedAt.toIso8601String(),
      'local_date': localDate,
      'replacement_index': replacementIndex,
      'status': RevealedStatus.active.name,
    });
  }

  Future<void> markRejected(String experienceId) async {
    await _updateStatus(experienceId, RevealedStatus.rejected);
  }

  Future<void> markCompleted(String experienceId) async {
    await _updateStatus(experienceId, RevealedStatus.completed);
  }

  Future<void> _updateStatus(String experienceId, RevealedStatus status) async {
    await (await _db).update(
      'revealed_experiences',
      {'status': status.name},
      where: 'experience_id = ?',
      whereArgs: [experienceId],
    );
  }

  Future<void> saveReflection(ReflectionRecord reflection) async {
    await (await _db).insert('reflections', {
      'experience_id': reflection.experienceId,
      'would_have_done_without_auren': reflection.wouldHaveDoneWithoutAuren
          ? 1
          : 0,
      'worth_time': reflection.worthTime ? 1 : 0,
      'note': reflection.note,
      'created_at': reflection.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> setting(String key) async {
    final rows = await (await _db).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    await (await _db).insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AurenUserData> exportUserData() async {
    final db = await _db;
    final settingsRows = await db.query('app_settings');
    return AurenUserData(
      revealed: await db.query(
        'revealed_experiences',
        orderBy: 'revealed_at ASC',
      ),
      reflections: await db.query('reflections', orderBy: 'created_at ASC'),
      settings: {
        for (final row in settingsRows)
          row['key'] as String: row['value'] as String,
      },
    );
  }

  Future<void> replaceUserData(AurenUserData data) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('reflections');
      await txn.delete('revealed_experiences');
      await txn.delete('app_settings');

      for (final row in data.revealed) {
        await txn.insert('revealed_experiences', {
          'experience_id': row['experience_id']?.toString() ?? '',
          'revealed_at': row['revealed_at']?.toString() ?? '',
          'local_date': row['local_date']?.toString() ?? '',
          'replacement_index': _readInt(row['replacement_index']),
          'status': row['status']?.toString() ?? RevealedStatus.active.name,
        });
      }

      for (final row in data.reflections) {
        await txn.insert('reflections', {
          'experience_id': row['experience_id']?.toString() ?? '',
          'would_have_done_without_auren':
              _readBool(row['would_have_done_without_auren']) ? 1 : 0,
          'worth_time': _readBool(row['worth_time']) ? 1 : 0,
          'note': row['note']?.toString() ?? '',
          'created_at': row['created_at']?.toString() ?? '',
        });
      }

      for (final entry in data.settings.entries) {
        await txn.insert('app_settings', {
          'key': entry.key,
          'value': entry.value,
        });
      }
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}
