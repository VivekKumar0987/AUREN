import 'package:flutter/material.dart';

import 'src/app/auren_controller.dart';

void main() {
  runApp(const AurenApp());
}

class AurenApp extends StatefulWidget {
  const AurenApp({super.key});

  @override
  State<AurenApp> createState() => _AurenAppState();
}

class _AurenAppState extends State<AurenApp> {
  late final AurenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AurenController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUREN',
      debugShowCheckedModeBanner: false,
      theme: AurenTheme.theme,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => AurenShell(controller: _controller),
      ),
    );
  }
}

class AurenTheme {
  static const paper = Color(0xfff3eddf);
  static const ink = Color(0xff1f211d);
  static const mutedInk = Color(0xff666257);
  static const ochre = Color(0xffa47a32);
  static const fieldGreen = Color(0xff34443a);
  static const oxblood = Color(0xff703c35);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ochre,
        brightness: Brightness.light,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
      fontFamily: 'Georgia',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: 'Georgia',
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          minimumSize: const Size(164, 48),
          shape: const RoundedRectangleBorder(),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1.4),
          minimumSize: const Size(148, 48),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xfffbf7eb),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: ink, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: ochre, width: 2),
        ),
      ),
    );
  }
}

class AurenShell extends StatelessWidget {
  const AurenShell({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: FieldNoteFrame(
                dateLabel: controller.todayLabel,
                child: _contentForState(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contentForState(BuildContext context) {
    switch (controller.viewState) {
      case AurenViewState.loading:
        return const LoadingView();
      case AurenViewState.welcome:
        return WelcomeView(controller: controller);
      case AurenViewState.blackBox:
        return BlackBoxView(controller: controller);
      case AurenViewState.unknown:
        return UnknownView(controller: controller);
      case AurenViewState.experience:
        return ExperienceView(controller: controller);
      case AurenViewState.reflection:
        return ReflectionView(controller: controller);
      case AurenViewState.share:
        return ShareView(controller: controller);
      case AurenViewState.archive:
        return ArchiveView(controller: controller);
      case AurenViewState.archiveDetail:
        return ArchiveDetailView(controller: controller);
      case AurenViewState.map:
        return MapView(controller: controller);
      case AurenViewState.backup:
        return BackupView(controller: controller);
      case AurenViewState.complete:
        return CompleteView(controller: controller);
      case AurenViewState.error:
        return ErrorView(controller: controller);
    }
  }
}

class FieldNoteFrame extends StatelessWidget {
  const FieldNoteFrame({
    super.key,
    required this.dateLabel,
    required this.child,
  });

  final String dateLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(
        color: AurenTheme.paper,
        border: Border.all(color: AurenTheme.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33221f18),
            blurRadius: 0,
            offset: Offset(8, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Header(dateLabel: dateLabel),
            const SizedBox(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key, required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'AUREN',
            style: TextStyle(
              fontFamily: 'Arial',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          dateLabel,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AurenTheme.mutedInk,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 120),
        BlackSquare(size: 56),
        SizedBox(height: 28),
        Text('Preparing the Black Box.'),
      ],
    );
  }
}

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 42),
        const BlackSquare(size: 72),
        const SizedBox(height: 42),
        const DisplayTitle('I do not know who you are.\nNeither do you.'),
        const SizedBox(height: 24),
        const BodyCopy("Let's find more of you."),
        const SizedBox(height: 44),
        ElevatedButton(
          onPressed: controller.finishIntroAndOpen,
          child: const Text('OPEN THE BLACK BOX'),
        ),
      ],
    );
  }
}

class BlackBoxView extends StatelessWidget {
  const BlackBoxView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionLabel('THE BLACK BOX'),
        const SizedBox(height: 22),
        const BlackSquare(size: 96),
        const SizedBox(height: 34),
        DisplayTitle(
          controller.revealedCount == 0
              ? 'Something is waiting.'
              : '${controller.unseenCount} Experiences remain unseen.',
        ),
        const SizedBox(height: 18),
        const BodyCopy('One day. One Experience. No feeds. No streaks.'),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: controller.openBox,
          child: const Text('OPEN'),
        ),
        const SizedBox(height: 28),
        NavRow(controller: controller),
      ],
    );
  }
}

class UnknownView extends StatelessWidget {
  const UnknownView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    final experience = controller.pendingUnknown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('UNKNOWN EXPERIENCE'),
        const SizedBox(height: 30),
        const Center(child: BlackSquare(size: 82)),
        const SizedBox(height: 32),
        const MetadataLine(label: 'Edition', value: 'Strong 160'),
        const MetadataLine(label: 'Success', value: 'Not required'),
        const MetadataLine(label: 'Repeat', value: 'Never shown again'),
        const SizedBox(height: 34),
        Center(
          child: ElevatedButton(
            onPressed: experience == null ? null : controller.revealPending,
            child: const Text('REVEAL'),
          ),
        ),
      ],
    );
  }
}

class ExperienceView extends StatelessWidget {
  const ExperienceView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    final experience = controller.currentExperience;
    if (experience == null) {
      return const BodyCopy('No Experience is currently active.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'FIELD EXPERIENCE / ${experience.id.replaceAll('AUREN-', '')}',
        ),
        const SizedBox(height: 18),
        DisplayTitle(experience.title.toUpperCase()),
        const DividerBlock(),
        BodyCopy(experience.instruction),
        const DividerBlock(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: controller.beginReflection,
              child: const Text('EXPERIENCED'),
            ),
            OutlinedButton(
              onPressed: controller.rejectCurrent,
              child: const Text('NOT THIS ONE'),
            ),
          ],
        ),
      ],
    );
  }
}

class ReflectionView extends StatefulWidget {
  const ReflectionView({super.key, required this.controller});

  final AurenController controller;

  @override
  State<ReflectionView> createState() => _ReflectionViewState();
}

class _ReflectionViewState extends State<ReflectionView> {
  bool? _wouldHaveDone;
  bool? _worthTime;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experience = widget.controller.currentExperience;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('EXPERIENCED'),
        const SizedBox(height: 18),
        DisplayTitle(experience?.title.toUpperCase() ?? 'FIELD NOTE'),
        const DividerBlock(),
        const QuestionBlock(
          question: 'Would you have done this without AUREN?',
        ),
        YesNoRow(
          value: _wouldHaveDone,
          onChanged: (value) => setState(() => _wouldHaveDone = value),
        ),
        const SizedBox(height: 26),
        const QuestionBlock(question: 'Was it worth your time?'),
        YesNoRow(
          value: _worthTime,
          onChanged: (value) => setState(() => _worthTime = value),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: _noteController,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Private note, optional',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: _wouldHaveDone == null || _worthTime == null
                  ? null
                  : () => widget.controller.saveReflection(
                      wouldHaveDoneWithoutAuren: _wouldHaveDone!,
                      worthTime: _worthTime!,
                      note: _noteController.text,
                    ),
              child: const Text('ARCHIVE'),
            ),
            OutlinedButton(
              onPressed: widget.controller.returnToExperience,
              child: const Text('BACK'),
            ),
          ],
        ),
      ],
    );
  }
}

class ShareView extends StatelessWidget {
  const ShareView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionLabel('FIELD NOTE SAVED'),
        const SizedBox(height: 24),
        DisplayTitle(
          controller.lastCompletedExperience?.title.toUpperCase() ??
              'EXPERIENCED',
        ),
        const SizedBox(height: 18),
        BodyCopy(controller.insightText()),
        const DividerBlock(),
        const QuestionBlock(
          question: 'Would you like to share this Experience with someone?',
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: controller.shareLastCompleted,
          child: const Text('SHARE'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: controller.copyLastShareText,
          child: const Text('COPY TEXT'),
        ),
        if (controller.statusMessage != null) ...[
          const SizedBox(height: 16),
          BodyCopy(controller.statusMessage!),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: controller.openBox,
          child: const Text('OPEN NEXT'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: controller.goHome, child: const Text('DONE')),
      ],
    );
  }
}

class CompleteView extends StatelessWidget {
  const CompleteView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionLabel('THE BLACK BOX IS EMPTY'),
        const SizedBox(height: 28),
        const BlackSquare(size: 76),
        const SizedBox(height: 30),
        const DisplayTitle('You opened every Experience in this edition.'),
        const SizedBox(height: 16),
        StatLine(label: 'Revealed', value: '${controller.revealedCount}'),
        StatLine(label: 'Experienced', value: '${controller.completedCount}'),
        StatLine(
          label: 'Archived',
          value: '${controller.archiveEntries.length}',
        ),
        const DividerBlock(),
        const BodyCopy('Nothing repeats here. The record remains.'),
        const SizedBox(height: 22),
        NavRow(controller: controller),
      ],
    );
  }
}

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    final entries = controller.archiveEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('AUREN ARCHIVE'),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const BodyCopy('No field notes are archived yet.')
        else
          for (final entry in entries)
            ArchiveEntryView(controller: controller, entry: entry),
        const SizedBox(height: 20),
        NavRow(controller: controller),
      ],
    );
  }
}

class ArchiveEntryView extends StatelessWidget {
  const ArchiveEntryView({
    super.key,
    required this.controller,
    required this.entry,
  });

  final AurenController controller;
  final ArchiveEntry entry;

  @override
  Widget build(BuildContext context) {
    final reflection = entry.reflection;
    return Semantics(
      button: true,
      label: 'Open archived field note ${entry.experience.title}',
      child: InkWell(
        onTap: () => controller.showArchiveDetail(entry.experience.id),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AurenController.formatDate(entry.revealed.revealedAt),
                style: const TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AurenTheme.ochre,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.experience.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (reflection != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Without AUREN: ${reflection.wouldHaveDoneWithoutAuren ? 'YES' : 'NO'}   Worth it: ${reflection.worthTime ? 'YES' : 'NO'}',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: AurenTheme.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class ArchiveDetailView extends StatelessWidget {
  const ArchiveDetailView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    final entry = controller.selectedArchiveEntry;
    if (entry == null) {
      return Column(
        children: [
          const SectionLabel('AUREN ARCHIVE'),
          const SizedBox(height: 18),
          const BodyCopy('That field note is not available.'),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: controller.showArchive,
            child: const Text('BACK'),
          ),
        ],
      );
    }

    final reflection = entry.reflection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('ARCHIVED FIELD NOTE'),
        const SizedBox(height: 12),
        Text(
          AurenController.formatDate(entry.revealed.revealedAt),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AurenTheme.ochre,
          ),
        ),
        const SizedBox(height: 18),
        DisplayTitle(entry.experience.title.toUpperCase()),
        const DividerBlock(),
        const SectionLabel('TASK'),
        const SizedBox(height: 14),
        BodyCopy(entry.experience.instruction),
        if (reflection != null) ...[
          const DividerBlock(),
          StatLine(
            label: 'Would have done without AUREN',
            value: reflection.wouldHaveDoneWithoutAuren ? 'YES' : 'NO',
          ),
          StatLine(
            label: 'Worth your time',
            value: reflection.worthTime ? 'YES' : 'NO',
          ),
          if (reflection.note.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionLabel('PRIVATE NOTE'),
            const SizedBox(height: 12),
            BodyCopy(reflection.note),
          ],
        ],
        const SizedBox(height: 28),
        Center(
          child: OutlinedButton(
            onPressed: controller.showArchive,
            child: const Text('BACK'),
          ),
        ),
      ],
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('AUREN MAP'),
        const SizedBox(height: 26),
        StatLine(
          label: 'Experiences in this edition',
          value: '${controller.totalCount}',
        ),
        StatLine(label: 'Revealed', value: '${controller.revealedCount}'),
        StatLine(label: 'Experienced', value: '${controller.completedCount}'),
        StatLine(label: 'Rejected', value: '${controller.rejectedCount}'),
        StatLine(label: 'Unseen', value: '${controller.unseenCount}'),
        const DividerBlock(),
        BodyCopy(controller.insightText()),
        const SizedBox(height: 26),
        LinearProgressIndicator(
          value: controller.totalCount == 0
              ? 0
              : controller.revealedCount / controller.totalCount,
          minHeight: 10,
          backgroundColor: const Color(0xffddd4c2),
          color: AurenTheme.fieldGreen,
        ),
        const SizedBox(height: 26),
        NavRow(controller: controller),
      ],
    );
  }
}

class BackupView extends StatefulWidget {
  const BackupView({super.key, required this.controller});

  final AurenController controller;

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  final TextEditingController _passphraseController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('BACKUP'),
        const SizedBox(height: 18),
        const DisplayTitle('Your exploration belongs to you.'),
        const SizedBox(height: 14),
        const BodyCopy(
          'Create an encrypted .aurenbackup file and save it anywhere you trust.',
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _passphraseController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Backup passphrase'),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(widget.controller.exportBackup),
              child: const Text('EXPORT'),
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(widget.controller.importBackup),
              child: const Text('RESTORE'),
            ),
          ],
        ),
        if (widget.controller.statusMessage != null) ...[
          const SizedBox(height: 18),
          BodyCopy(widget.controller.statusMessage!),
        ],
        const SizedBox(height: 22),
        NavRow(controller: widget.controller),
      ],
    );
  }

  Future<void> _run(Future<void> Function(String passphrase) action) async {
    setState(() => _busy = true);
    try {
      await action(_passphraseController.text);
    } catch (error) {
      widget.controller.showStatus(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionLabel('AUREN COULD NOT OPEN'),
        const SizedBox(height: 18),
        BodyCopy(controller.errorMessage ?? 'Unknown error.'),
      ],
    );
  }
}

class NavRow extends StatelessWidget {
  const NavRow({super.key, required this.controller});

  final AurenController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton(onPressed: controller.goHome, child: const Text('BOX')),
        OutlinedButton(
          onPressed: controller.showArchive,
          child: const Text('ARCHIVE'),
        ),
        OutlinedButton(onPressed: controller.showMap, child: const Text('MAP')),
        OutlinedButton(
          onPressed: controller.showBackup,
          child: const Text('BACKUP'),
        ),
      ],
    );
  }
}

class BlackSquare extends StatelessWidget {
  const BlackSquare({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'The Black Box',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AurenTheme.ink,
          boxShadow: [
            BoxShadow(
              color: Color(0x55332d22),
              blurRadius: 0,
              offset: Offset(5, 5),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayTitle extends StatelessWidget {
  const DisplayTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 34,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class BodyCopy extends StatelessWidget {
  const BodyCopy(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, height: 1.45, letterSpacing: 0),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 13,
        color: AurenTheme.ochre,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class MetadataLine extends StatelessWidget {
  const MetadataLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class StatLine extends StatelessWidget {
  const StatLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Arial',
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class DividerBlock extends StatelessWidget {
  const DividerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, color: AurenTheme.ink, thickness: 1.2),
    );
  }
}

class QuestionBlock extends StatelessWidget {
  const QuestionBlock({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Text(
      question,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class YesNoRow extends StatelessWidget {
  const YesNoRow({super.key, required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('YES')),
          ButtonSegment(value: false, label: Text('NO')),
        ],
        selected: value == null ? const <bool>{} : {value!},
        emptySelectionAllowed: true,
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
      ),
    );
  }
}
