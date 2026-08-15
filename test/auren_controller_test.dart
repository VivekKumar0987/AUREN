import 'package:auren/src/app/auren_controller.dart';
import 'package:auren/src/catalog/experience.dart';
import 'package:auren/src/catalog/experience_catalog_loader.dart';
import 'package:auren/src/storage/auren_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const dbPath = 'controller_flow.db';

  setUp(() async {
    sqfliteFfiInit();
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  test(
    'completed experience does not block opening another experience',
    () async {
      final database = AurenDatabase(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      final controller = AurenController(
        catalogLoader: _FakeCatalogLoader(),
        database: database,
        clock: () => DateTime(2026, 8, 15, 9),
      );

      await controller.initialize();
      expect(controller.viewState, AurenViewState.welcome);

      await controller.finishIntroAndOpen();
      expect(controller.viewState, AurenViewState.unknown);

      final first = controller.pendingUnknown;
      expect(first, isNotNull);

      await controller.revealPending();
      expect(controller.viewState, AurenViewState.experience);

      controller.beginReflection();
      expect(controller.viewState, AurenViewState.reflection);

      await controller.saveReflection(
        wouldHaveDoneWithoutAuren: false,
        worthTime: true,
        note: 'Worth remembering.',
      );
      expect(controller.viewState, AurenViewState.share);
      expect(controller.archiveEntries, hasLength(1));

      controller.showArchiveDetail(first!.id);
      expect(controller.viewState, AurenViewState.archiveDetail);
      expect(
        controller.selectedArchiveEntry?.experience.instruction,
        first.instruction,
      );

      controller.goHome();
      expect(controller.viewState, AurenViewState.blackBox);

      await controller.openBox();
      expect(controller.viewState, AurenViewState.unknown);
      expect(controller.pendingUnknown?.id, isNot(first.id));

      await database.close();
      controller.dispose();
    },
  );
}

class _FakeCatalogLoader extends ExperienceCatalogLoader {
  @override
  Future<ExperienceCatalog> load({AssetBundle? bundle}) async {
    final experiences = List<Experience>.generate(160, (index) {
      final number = index + 1;
      return Experience(
        id: 'AUREN-${number.toString().padLeft(4, '0')}',
        title: 'Field note $number',
        instruction:
            'Observe one real thing carefully and record detail $number.',
        status: 'strong_editorial_candidate_pending_field_test',
        repeatPolicy: ExperienceCatalog.expectedRepeatPolicy,
        consumerBrowsable: false,
        requiresSuccess: false,
        postExperienceQuestions: const [
          'Would you have done this without AUREN?',
          'Was it worth your time?',
        ],
        sharePrompt: 'Would you like to share the experience with someone?',
      );
    });

    return ExperienceCatalog(
      app: 'AUREN',
      declaredCount: 160,
      note: '',
      experiences: experiences,
    );
  }
}
