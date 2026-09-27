import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/theme.dart';
import 'package:wanderlock/features/story/domain/story_chapter.dart';
import 'package:wanderlock/features/story/presentation/story_player.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// What a reader standing at the place actually sees.
///
/// The parsing tests below this one prove a chapter survives the file format;
/// these prove it reaches the screen, which is a different failure.
void main() {
  const chapter = StoryChapter(
    id: 'independence-palace',
    checkpointId: 'independence-palace',
    title: 'Toà nhà của một bước ngoặt',
    source: 'Wikipedia tiếng Việt — Dinh Độc Lập',
    nodes: [
      Narration('Đoạn mở đầu của chương.'),
      Narration('Đoạn thứ hai, vẫn còn dấu tiếng Việt: ế ỡ ộ ữ ẫ.'),
    ],
  );

  Future<void> pumpPlayer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StoryPlayer(
          chapter: chapter,
          placeName: 'Dinh Độc Lập',
          landmark: 'palace',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the place, the title and every paragraph', (tester) async {
    await pumpPlayer(tester);

    expect(find.text('DINH ĐỘC LẬP'), findsOneWidget);
    expect(find.text('Toà nhà của một bước ngoặt'), findsOneWidget);
    expect(find.text('Đoạn mở đầu của chương.'), findsOneWidget);
    expect(
      find.text('Đoạn thứ hai, vẫn còn dấu tiếng Việt: ế ỡ ộ ữ ẫ.'),
      findsOneWidget,
    );
  });

  // A chapter written from somebody else's research says so on the page, not
  // only in the JSON. Dropping the credit silently is the failure worth a test.
  testWidgets('credits the source it was written from', (tester) async {
    await pumpPlayer(tester);

    expect(
      find.textContaining('Wikipedia tiếng Việt — Dinh Độc Lập'),
      findsOneWidget,
    );
  });

  testWidgets('says how long the read is before it starts', (tester) async {
    await pumpPlayer(tester);

    expect(find.textContaining('2'), findsWidgets);
  });
}
