import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gathermap/core/theme/app_themes.dart';
import 'package:gathermap/features/events/domain/event.dart';
import 'package:gathermap/features/events/domain/event_guest.dart';
import 'package:gathermap/features/events/domain/event_guest_repository.dart';
import 'package:gathermap/features/events/presentation/event_guest_controller.dart';
import 'package:gathermap/features/events/presentation/widgets/event_detail_sheet.dart';

Event _event({
  String id = 'evt-1',
  DateTime? scheduledAt,
  bool isPublic = true,
}) => Event(
  id: id,
  ownerId: 'owner-1',
  scheduledAt: scheduledAt ?? DateTime(2026, 10, 25, 20),
  location: 'Rooftop, Place du Capitole',
  createdAt: DateTime(2026, 10, 1, 9),
  name: 'Rooftop Party',
  emojiIcon: '🎉',
  color: '#FF5A1F',
  isPublic: isPublic,
  latitude: 43.6045,
  longitude: 1.4442,
);

EventGuestBook _book() => EventGuestBook(
  organizer: const EventPerson(
    id: 'owner-1',
    displayName: 'Maya Chen',
    username: 'maya',
  ),
  guests: const [
    EventGuest(
      person: EventPerson(id: 'lea', displayName: 'Léa', username: 'lea'),
      accepted: true,
    ),
    EventGuest(
      person: EventPerson(id: 'tom', displayName: 'Tom', username: 'tom'),
      accepted: true,
    ),
    EventGuest(
      person: EventPerson(id: 'ines', displayName: 'Inès', username: 'ines'),
      accepted: null,
    ),
    EventGuest(
      person: EventPerson(id: 'marc', displayName: 'Marc', username: 'marc'),
      accepted: false,
    ),
  ],
);

class _FakeGuestRepository implements EventGuestRepository {
  _FakeGuestRepository({this.book});

  final EventGuestBook? book;
  final List<String> requestedEventIds = [];

  @override
  Future<EventGuestBook> fetchForEvent(
    String eventId, {
    required String ownerId,
  }) async {
    requestedEventIds.add(eventId);
    return book ?? const EventGuestBook();
  }
}

Widget _harness(
  Event event,
  EventGuestController controller, {
  VoidCallback? onClose,
}) {
  return ChangeNotifierProvider<EventGuestController>.value(
    value: controller,
    child: MaterialApp(
      theme: AppThemes.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 700,
          child: Stack(
            children: [
              Positioned.fill(
                child: EventDetailSheet(
                  event: event,
                  onClose: onClose ?? () {},
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('compact sheet shows event summary and RSVP actions', (
    tester,
  ) async {
    final repository = _FakeGuestRepository(book: _book());
    final controller = EventGuestController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    expect(find.text('Rooftop Party'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.textContaining('25 oct.'), findsOneWidget);
    expect(find.text('Je viens'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.textContaining('peut-être', findRichText: true), findsNothing);
    expect(find.byKey(const ValueKey('rsvp-attend')), findsOneWidget);
    expect(find.byKey(const ValueKey('rsvp-decline')), findsOneWidget);
    expect(repository.requestedEventIds, ['evt-1']);
  });

  testWidgets('shows the organiser returned with the guest book', (
    tester,
  ) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('organisé par', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('dragging up expands the sheet', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('event-detail-panel'));
    final before = tester.getTopLeft(panel).dy;

    await tester.drag(
      find.byKey(const ValueKey('event-detail-handle')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(panel).dy;
    expect(after, lessThan(before));
    expect(after, moreOrLessEquals(0, epsilon: 1));
  });

  testWidgets('scrolling content does not resize the sheet', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('event-detail-panel'));
    final content = find.byKey(const ValueKey('event-detail-scroll'));
    final title = find.text('Rooftop Party');
    final sheetTop = tester.getTopLeft(panel).dy;
    final titleTop = tester.getTopLeft(title).dy;

    await tester.drag(content, const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(panel).dy, moreOrLessEquals(sheetTop, epsilon: 1));
    expect(tester.getTopLeft(title).dy, lessThan(titleTop));

    await tester.drag(content, const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(panel).dy, moreOrLessEquals(sheetTop, epsilon: 1));
  });

  testWidgets('dragging down closes the sheet', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);
    var closed = false;

    await tester.pumpWidget(
      _harness(_event(), controller, onClose: () => closed = true),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('event-detail-handle')),
      const Offset(0, 240),
    );
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('guest tab lists invitations with their answers', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    // Scroll the content (not the sheet) until the tab strip is visible.
    await tester.drag(
      find.byKey(const ValueKey('event-detail-scroll')),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('INVITÉS'));
    await tester.pumpAndSettle();

    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('Tom'), findsOneWidget);
    expect(find.text('Inès'), findsOneWidget);
    expect(find.text('Marc'), findsOneWidget);
    expect(find.text('Présent'), findsNWidgets(2));
    expect(find.text('En attente'), findsOneWidget);
    // One guest status pill plus the always-visible RSVP action button.
    expect(find.text('Absent'), findsNWidgets(2));
  });

  testWidgets('placeholder tabs render their empty state', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('event-detail-scroll')),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PHOTOS'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune photo'), findsOneWidget);
  });

  testWidgets('RSVP buttons are tappable no-ops', (tester) async {
    final repository = _FakeGuestRepository(book: _book());
    final controller = EventGuestController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(_event(), controller));
    await tester.pumpAndSettle();

    final callsBefore = repository.requestedEventIds.length;

    await tester.tap(find.byKey(const ValueKey('rsvp-attend')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rsvp-decline')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(controller.attending, 2);
    expect(repository.requestedEventIds.length, callsBefore);
  });

  testWidgets('close button calls onClose', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    var closed = false;
    await tester.pumpWidget(
      _harness(_event(), controller, onClose: () => closed = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('event-detail-close')));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('past events are labelled Passé', (tester) async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _harness(
        _event(scheduledAt: DateTime.now().subtract(const Duration(days: 2))),
        controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passé'), findsOneWidget);
  });
}
