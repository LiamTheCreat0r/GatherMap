import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/error/describe_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('describeError', () {
    test('uses the Supabase message and error code', () {
      final message = describeError(
        const PostgrestApiException(
          message: 'permission denied',
          statusCode: 42501,
          errorCode: '42501',
        ),
      );

      expect(message, 'permission denied (42501)');
    });

    test('falls back to the HTTP status when no code is reported', () {
      final message = describeError(
        const PostgrestApiException(message: 'not found', statusCode: 404),
      );

      expect(message, 'not found (HTTP 404)');
    });

    test('names a failed realtime subscription', () {
      final message = describeError(
        const RealtimeSubscribeException(RealtimeSubscribeStatus.timedOut),
      );

      expect(message, contains('Realtime subscription failed'));
      expect(message, contains('timedOut'));
    });

    test('keeps unknown errors readable', () {
      expect(describeError(StateError('boom')), contains('boom'));
    });
  });
}
