import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/state/base_controller.dart';
import 'package:gathermap/features/events/domain/event.dart';
import 'package:gathermap/features/events/domain/event_guest.dart';
import 'package:gathermap/features/events/domain/event_guest_repository.dart';
import 'package:gathermap/features/events/presentation/event_guest_controller.dart';

Event _event({String id = 'evt-1', String ownerId = 'owner-1'}) => Event(
  id: id,
  ownerId: ownerId,
  scheduledAt: DateTime.utc(2026, 10, 25, 20),
  location: 'Place du Capitole',
  createdAt: DateTime.utc(2026, 10, 1),
  name: 'Rooftop Party',
  emojiIcon: '🎉',
  color: '#FF5A1F',
  isPublic: true,
  latitude: 43.6045,
  longitude: 1.4442,
);

EventPerson _person(String name, {String? id}) => EventPerson(
  id: id ?? name.toLowerCase(),
  displayName: name,
  username: name.toLowerCase(),
);

EventGuestBook _book() => EventGuestBook(
  organizer: _person('Maya Chen', id: 'owner-1'),
  guests: [
    EventGuest(person: _person('Léa'), accepted: true),
    EventGuest(person: _person('Tom'), accepted: true),
    EventGuest(person: _person('Inès'), accepted: null),
    EventGuest(person: _person('Marc'), accepted: false),
  ],
);

/// Repository returning a fixed guest book, with an optional error.
class _FakeGuestRepository implements EventGuestRepository {
  _FakeGuestRepository({this.book, this.error});

  final EventGuestBook? book;
  final Object? error;
  final List<String> requestedEventIds = [];

  @override
  Future<EventGuestBook> fetchForEvent(
    String eventId, {
    required String ownerId,
  }) async {
    requestedEventIds.add(eventId);
    if (error != null) throw error!;
    return book ?? const EventGuestBook();
  }
}

/// Repository whose responses are completed manually, to test stale loads.
class _DeferredGuestRepository implements EventGuestRepository {
  final Map<String, Completer<EventGuestBook>> pending = {};

  @override
  Future<EventGuestBook> fetchForEvent(
    String eventId, {
    required String ownerId,
  }) {
    final completer = Completer<EventGuestBook>();
    pending[eventId] = completer;
    return completer.future;
  }
}

void main() {
  test('counts attending, unanswered and declined guests', () async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await controller.loadFor(_event());

    expect(controller.attending, 2);
    expect(controller.maybe, 1);
    expect(controller.declined, 1);
    expect(controller.organizer?.displayName, 'Maya Chen');
    expect(controller.status, ControllerStatus.ready);
  });

  test('a failed load lands in status/error instead of throwing', () async {
    final controller = EventGuestController(
      _FakeGuestRepository(error: StateError('offline')),
    );
    addTearDown(controller.dispose);

    await controller.loadFor(_event());

    expect(controller.status, ControllerStatus.error);
    expect(controller.error, contains('offline'));
    expect(controller.guests, isEmpty);
  });

  test('a slow response cannot overwrite a newer event', () async {
    final repository = _DeferredGuestRepository();
    final controller = EventGuestController(repository);
    addTearDown(controller.dispose);

    final first = controller.loadFor(_event(id: 'evt-a'));
    final second = controller.loadFor(_event(id: 'evt-b'));

    repository.pending['evt-b']!.complete(
      EventGuestBook(
        guests: [EventGuest(person: _person('Nina'), accepted: true)],
      ),
    );
    await second;

    repository.pending['evt-a']!.complete(
      EventGuestBook(
        guests: [EventGuest(person: _person('Old Guest'), accepted: true)],
      ),
    );
    await first;

    expect(controller.eventId, 'evt-b');
    expect(controller.guests.single.person.displayName, 'Nina');
  });

  test('clear drops the loaded event', () async {
    final controller = EventGuestController(
      _FakeGuestRepository(book: _book()),
    );
    addTearDown(controller.dispose);

    await controller.loadFor(_event());
    controller.clear();

    expect(controller.eventId, isNull);
    expect(controller.guests, isEmpty);
    expect(controller.attending, 0);
  });
}
