import 'package:auren/src/backup/backup_service.dart';
import 'package:auren/src/storage/auren_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const sourceDbPath = 'backup_round_trip_source.db';
  const targetDbPath = 'backup_round_trip_target.db';
  const wrongPassphraseDbPath = 'backup_wrong_passphrase.db';

  setUp(() async {
    sqfliteFfiInit();
    await databaseFactoryFfi.deleteDatabase(sourceDbPath);
    await databaseFactoryFfi.deleteDatabase(targetDbPath);
    await databaseFactoryFfi.deleteDatabase(wrongPassphraseDbPath);
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(sourceDbPath);
    await databaseFactoryFfi.deleteDatabase(targetDbPath);
    await databaseFactoryFfi.deleteDatabase(wrongPassphraseDbPath);
  });

  test('backup export and restore round trip user state', () async {
    final firstDb = AurenDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: sourceDbPath,
    );
    await firstDb.open();
    await firstDb.revealExperience(
      experienceId: 'AUREN-0001',
      revealedAt: DateTime.utc(2026, 8, 15),
      localDate: '2026-08-15',
      replacementIndex: 0,
    );
    await firstDb.markCompleted('AUREN-0001');
    await firstDb.saveReflection(
      ReflectionRecord(
        experienceId: 'AUREN-0001',
        wouldHaveDoneWithoutAuren: false,
        worthTime: true,
        note: 'Worth remembering.',
        createdAt: DateTime.utc(2026, 8, 15, 10),
      ),
    );

    final backup = await BackupService(firstDb)
        .exportEncrypted(passphrase: 'strong-passphrase');

    final secondDb = AurenDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: targetDbPath,
    );
    await secondDb.open();
    await BackupService(secondDb).restoreEncrypted(
      encryptedBackup: backup,
      passphrase: 'strong-passphrase',
    );

    final revealed = await secondDb.revealedExperienceIds();
    final reflections = await secondDb.reflections();

    expect(revealed, contains('AUREN-0001'));
    expect(reflections.single.wouldHaveDoneWithoutAuren, isFalse);
    expect(reflections.single.worthTime, isTrue);

    await firstDb.close();
    await secondDb.close();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('backup restore rejects wrong passphrase', () async {
    final db = AurenDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: wrongPassphraseDbPath,
    );
    await db.open();
    final backup = await BackupService(db)
        .exportEncrypted(passphrase: 'strong-passphrase');

    await expectLater(
      BackupService(db).restoreEncrypted(
        encryptedBackup: backup,
        passphrase: 'wrong-passphrase',
      ),
      throwsFormatException,
    );

    await db.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
