import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup/backup_service.dart';
import '../catalog/experience.dart';
import '../catalog/experience_catalog_loader.dart';
import '../engine/selection_engine.dart';
import '../share/share_template.dart';
import '../storage/auren_database.dart';

enum AurenViewState {
  loading,
  welcome,
  blackBox,
  unknown,
  experience,
  reflection,
  share,
  archive,
  archiveDetail,
  map,
  backup,
  complete,
  error,
}

class ArchiveEntry {
  const ArchiveEntry({
    required this.experience,
    required this.revealed,
    required this.reflection,
  });

  final Experience experience;
  final RevealedExperienceRecord revealed;
  final ReflectionRecord? reflection;
}

class AurenController extends ChangeNotifier {
  AurenController({
    this.catalogLoader = const ExperienceCatalogLoader(),
    AurenDatabase? database,
    this.selectionEngine = const SelectionEngine(),
    DateTime Function()? clock,
  }) : _database = database ?? AurenDatabase(),
       _clock = clock ?? DateTime.now;

  static const String _firstLaunchCompleteKey = 'first_launch_complete';

  final ExperienceCatalogLoader catalogLoader;
  final AurenDatabase _database;
  final SelectionEngine selectionEngine;
  final DateTime Function() _clock;

  AurenViewState viewState = AurenViewState.loading;
  ExperienceCatalog? catalog;
  Experience? pendingUnknown;
  Experience? currentExperience;
  Experience? lastCompletedExperience;
  ReflectionRecord? lastReflection;
  String? errorMessage;
  String? statusMessage;
  String? selectedArchiveExperienceId;

  int revealedCount = 0;
  int completedCount = 0;
  int rejectedCount = 0;
  int totalCount = ExperienceCatalog.requiredCount;
  List<ArchiveEntry> archiveEntries = const [];

  int get unseenCount => totalCount - revealedCount;
  bool get isComplete => unseenCount <= 0;
  String get todayLabel => formatDate(_clock());

  List<RevealedExperienceRecord> _todayRevealed = const [];
  List<RevealedExperienceRecord> _allRevealed = const [];
  List<ReflectionRecord> _allReflections = const [];

  Future<void> initialize() async {
    try {
      viewState = AurenViewState.loading;
      notifyListeners();

      catalog = await catalogLoader.load();
      final validationErrors = catalog!.validate();
      if (validationErrors.isNotEmpty) {
        throw StateError(validationErrors.join('\n'));
      }

      await _database.open();
      await _reloadUserState();

      final hasSeenIntro =
          await _database.setting(_firstLaunchCompleteKey) == 'true';
      viewState = hasSeenIntro ? _nextHomeState() : AurenViewState.welcome;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      viewState = AurenViewState.error;
      notifyListeners();
    }
  }

  Future<void> finishIntroAndOpen() async {
    await _database.setSetting(_firstLaunchCompleteKey, 'true');
    await openBox();
  }

  Future<void> openBox() async {
    final loadedCatalog = catalog;
    if (loadedCatalog == null) {
      return;
    }
    await _reloadUserState();
    statusMessage = null;

    if (isComplete) {
      viewState = AurenViewState.complete;
      notifyListeners();
      return;
    }

    final existingActive = _allRevealed.where(
      (record) => record.status == RevealedStatus.active,
    );
    if (existingActive.isNotEmpty) {
      currentExperience = loadedCatalog.byId[existingActive.last.experienceId];
      viewState = AurenViewState.experience;
      notifyListeners();
      return;
    }

    final revealedIds = _allRevealed
        .map((record) => record.experienceId)
        .toSet();
    final recent = _allRevealed
        .map((record) => loadedCatalog.byId[record.experienceId])
        .whereType<Experience>()
        .toList(growable: false);

    pendingUnknown = selectionEngine.choose(
      catalog: loadedCatalog,
      revealedExperienceIds: revealedIds,
      recentExperiences: recent,
      localDate: _clock(),
      salt: _allRevealed.length,
    );

    viewState = pendingUnknown == null
        ? AurenViewState.complete
        : AurenViewState.unknown;
    notifyListeners();
  }

  Future<void> revealPending() async {
    final experience = pendingUnknown;
    if (experience == null) {
      return;
    }
    final now = _clock();
    await _database.revealExperience(
      experienceId: experience.id,
      revealedAt: now,
      localDate: localDateKey(now),
      replacementIndex: _todayRevealed.length,
    );
    pendingUnknown = null;
    currentExperience = experience;
    await _reloadUserState();
    viewState = AurenViewState.experience;
    notifyListeners();
  }

  Future<void> rejectCurrent() async {
    final experience = currentExperience;
    if (experience == null) {
      return;
    }
    await _database.markRejected(experience.id);
    currentExperience = null;
    await _reloadUserState();
    viewState = AurenViewState.blackBox;
    notifyListeners();
  }

  void beginReflection() {
    if (currentExperience == null) {
      return;
    }
    viewState = AurenViewState.reflection;
    notifyListeners();
  }

  void returnToExperience() {
    if (currentExperience == null) {
      return;
    }
    viewState = AurenViewState.experience;
    notifyListeners();
  }

  Future<void> saveReflection({
    required bool wouldHaveDoneWithoutAuren,
    required bool worthTime,
    required String note,
  }) async {
    final experience = currentExperience;
    if (experience == null) {
      return;
    }

    final reflection = ReflectionRecord(
      experienceId: experience.id,
      wouldHaveDoneWithoutAuren: wouldHaveDoneWithoutAuren,
      worthTime: worthTime,
      note: note.trim(),
      createdAt: _clock(),
    );
    await _database.markCompleted(experience.id);
    await _database.saveReflection(reflection);

    lastCompletedExperience = experience;
    lastReflection = reflection;
    currentExperience = null;
    await _reloadUserState();
    viewState = AurenViewState.share;
    notifyListeners();
  }

  void showArchive() {
    selectedArchiveExperienceId = null;
    viewState = AurenViewState.archive;
    notifyListeners();
  }

  void showArchiveDetail(String experienceId) {
    selectedArchiveExperienceId = experienceId;
    viewState = AurenViewState.archiveDetail;
    notifyListeners();
  }

  ArchiveEntry? get selectedArchiveEntry {
    final selectedId = selectedArchiveExperienceId;
    if (selectedId == null) {
      return null;
    }
    for (final entry in archiveEntries) {
      if (entry.experience.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  void showMap() {
    viewState = AurenViewState.map;
    notifyListeners();
  }

  void showBackup() {
    statusMessage = null;
    viewState = AurenViewState.backup;
    notifyListeners();
  }

  void showStatus(String message) {
    statusMessage = message;
    notifyListeners();
  }

  void goHome() {
    statusMessage = null;
    viewState = _nextHomeState();
    notifyListeners();
  }

  Future<void> shareLastCompleted() async {
    final experience = lastCompletedExperience;
    if (experience == null) {
      return;
    }
    final template = _shareTemplateFor(experience);
    await SharePlus.instance.share(
      ShareParams(text: template.text, subject: template.subject),
    );
  }

  Future<void> copyLastShareText() async {
    final experience = lastCompletedExperience;
    if (experience == null) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: _shareTemplateFor(experience).text),
    );
    showStatus('Share text copied.');
  }

  Future<void> exportBackup(String passphrase) async {
    final backup = await BackupService(_database)
        .exportEncrypted(passphrase: passphrase);
    final fileName =
        'auren-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.aurenbackup';

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'AUREN backup', extensions: ['aurenbackup']),
        ],
      );
      if (location == null) {
        statusMessage = 'Backup export cancelled.';
        notifyListeners();
        return;
      }
      await File(location.path).writeAsString(backup, encoding: utf8);
      statusMessage = 'Encrypted backup saved.';
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(backup, encoding: utf8);
      await SharePlus.instance.share(
        ShareParams(
          text: 'Encrypted AUREN backup',
          files: [
            XFile(file.path, mimeType: 'application/json', name: fileName),
          ],
        ),
      );
      statusMessage = 'Encrypted backup prepared for saving.';
    }
    notifyListeners();
  }

  Future<void> importBackup(String passphrase) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'AUREN backup', extensions: ['aurenbackup', 'json']),
      ],
    );
    if (file == null) {
      statusMessage = 'Restore cancelled.';
      notifyListeners();
      return;
    }

    final encryptedBackup = await file.readAsString();
    final rollback = await BackupService(_database).restoreEncrypted(
      encryptedBackup: encryptedBackup,
      passphrase: passphrase,
    );
    await _writeRollbackBackup(rollback);
    await _reloadUserState();
    statusMessage = 'Backup restored. A rollback backup was saved locally.';
    viewState = _nextHomeState();
    notifyListeners();
  }

  String insightText() {
    if (_allReflections.isEmpty) {
      return 'AUREN has not seen enough of you yet.';
    }

    final noDefault = _allReflections
        .where((reflection) => !reflection.wouldHaveDoneWithoutAuren)
        .length;
    final worthIt = _allReflections
        .where((reflection) => reflection.worthTime)
        .length;

    if (noDefault > 0 && worthIt > 0) {
      return 'AUREN has noticed that some Experiences you would not normally choose still became worth your time.';
    }
    if (worthIt > 0) {
      return 'AUREN has noticed that your Archive is beginning to hold worthwhile traces.';
    }
    return 'AUREN has noticed first patterns, but nothing here is a verdict.';
  }

  AurenViewState _nextHomeState() {
    if (isComplete) {
      return AurenViewState.complete;
    }
    return AurenViewState.blackBox;
  }

  Future<void> _reloadUserState() async {
    final loadedCatalog = catalog;
    if (loadedCatalog == null) {
      return;
    }

    final today = localDateKey(_clock());
    _allRevealed = (await _database.recentRevealed(limit: 10000)).reversed
        .toList(growable: false);
    _todayRevealed = await _database.revealedForDate(today);
    _allReflections = await _database.reflections();

    final reflectionById = {
      for (final reflection in _allReflections)
        reflection.experienceId: reflection,
    };

    revealedCount = _allRevealed.length;
    completedCount = _allRevealed
        .where((record) => record.status == RevealedStatus.completed)
        .length;
    rejectedCount = _allRevealed
        .where((record) => record.status == RevealedStatus.rejected)
        .length;
    totalCount = loadedCatalog.experiences.length;

    archiveEntries = _allRevealed
        .where((record) => record.status == RevealedStatus.completed)
        .map((record) {
          final experience = loadedCatalog.byId[record.experienceId];
          if (experience == null) {
            return null;
          }
          return ArchiveEntry(
            experience: experience,
            revealed: record,
            reflection: reflectionById[record.experienceId],
          );
        })
        .whereType<ArchiveEntry>()
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  }

  AurenShareTemplate _shareTemplateFor(Experience experience) {
    return AurenShareTemplate.forExperience(
      experience: experience,
      date: lastReflection?.createdAt ?? _clock(),
    );
  }

  Future<void> _writeRollbackBackup(String rollback) async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = File(
      p.join(
        directory.path,
        'auren-rollback-${DateTime.now().toUtc().millisecondsSinceEpoch}.aurenbackup',
      ),
    );
    await file.writeAsString(rollback, encoding: utf8);
  }

  static String localDateKey(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String formatDate(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
