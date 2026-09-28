import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/screens/checkpoint_sheet.dart';
import 'package:wanderlock/app/theme.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/itinerary/application/itinerary_providers.dart';
import 'package:wanderlock/features/story/domain/story_chapter.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The seam between the unlock layer and the Story lens.
///
/// A chapter opens because `visit_state` says the place was visited, and for
/// no other reason. These check the seam from the outside: the button a reader
/// can actually press.
void main() {
  const chapter = StoryChapter(
    id: 'palace',
    checkpointId: 'independence-palace',
    title: 'Toà nhà của một bước ngoặt',
    source: 'Wikipedia',
    nodes: [Narration('Một đoạn.')],
  );

  const checkpoint = Checkpoint(
    id: 'independence-palace',
    name: 'Dinh Độc Lập',
    category: CheckpointCategory.monument,
    latitude: 10.7768269,
    longitude: 106.6951472,
    radiusMeters: 60,
  );

  StoryChapter? opened;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required bool isVisited,
    Map<String, StoryChapter> chapters = const {'independence-palace': chapter},
  }) async {
    opened = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storyChaptersProvider.overrideWith((ref) async => chapters),
          itineraryOrderProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CheckpointSheet(
              checkpoint: checkpoint,
              isVisited: isVisited,
              onDismiss: () {},
              onReadStory: (c) => opened = c,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a visited place offers its chapter', (tester) async {
    await pumpSheet(tester, isVisited: true);

    final button = find.byKey(const Key('read-story'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(opened, same(chapter));
  });

  // Shown but dead, not hidden: knowing a chapter is waiting is a reason to
  // walk over. What must never happen is reading it without going.
  testWidgets('a locked place shows the chapter but will not open it', (
    tester,
  ) async {
    await pumpSheet(tester, isVisited: false);

    final button = find.byKey(const Key('read-story'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(opened, isNull);
  });

  testWidgets('a place with no chapter shows no story button at all', (
    tester,
  ) async {
    await pumpSheet(tester, isVisited: true, chapters: const {});

    expect(find.byKey(const Key('read-story')), findsNothing);
  });
}
