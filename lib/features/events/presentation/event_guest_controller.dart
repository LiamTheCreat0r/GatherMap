import '../../../../core/state/base_controller.dart';
import '../domain/event.dart';
import '../domain/event_guest.dart';
import '../domain/event_guest_repository.dart';

/// Loads the guests and organiser for the event currently open in the detail
/// sheet.
///
/// One controller is shared by the app: [loadFor] replaces its contents when
/// the user taps a different pin. A monotonically increasing token discards a
/// slow response that lands after a newer event has already been requested.
class EventGuestController extends BaseController {
  EventGuestController(this._repository);

  final EventGuestRepository _repository;

  EventGuestBook _book = const EventGuestBook();
  String? _eventId;
  int _loadToken = 0;

  /// The event whose guest book is loaded, if any.
  String? get eventId => _eventId;

  /// Guests and organiser currently held.
  EventGuestBook get book => _book;

  /// The event's owner profile, when visible.
  EventPerson? get organizer => _book.organizer;

  /// Invitation rows joined with their profiles.
  List<EventGuest> get guests => _book.guests;

  /// Guests who answered yes.
  int get attending =>
      _book.guests.where((guest) => guest.accepted == true).length;

  /// Guests who have not answered yet.
  int get maybe => _book.guests.where((guest) => guest.accepted == null).length;

  /// Guests who answered no.
  int get declined =>
      _book.guests.where((guest) => guest.accepted == false).length;

  /// Loads the guest book for [event].
  ///
  /// Clears the previous event's data as soon as a different event is opened,
  /// so the sheet never flashes the wrong names while the query runs.
  Future<void> loadFor(Event event) {
    if (_eventId != event.id) {
      _eventId = event.id;
      _book = const EventGuestBook();
    }

    final token = ++_loadToken;
    return runAction(() async {
      final loaded = await _repository.fetchForEvent(
        event.id,
        ownerId: event.ownerId,
      );
      if (token != _loadToken) return;
      _book = loaded;
    });
  }

  /// Drops the loaded guest book, e.g. when the detail sheet closes.
  void clear() {
    _loadToken++;
    _eventId = null;
    _book = const EventGuestBook();
    notifySafely();
  }
}
