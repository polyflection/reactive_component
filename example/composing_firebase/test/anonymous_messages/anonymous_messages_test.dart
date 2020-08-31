import 'dart:async';

import 'package:composing_firebase/anonymous_messages/anonymous_messages.dart';
import 'package:composing_firebase/anonymous_messages/message.dart';
import 'package:composing_firebase/anonymous_messages/messages_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _FakeRepository extends Fake implements MessagesRepository {
  final controller = StreamController<List<Message>>();
  @override
  Stream<List<Message>> get messages => controller.stream;
}

void main() {
  group(AnonymousMessages, () {
    _FakeRepository repository;
    AnonymousMessages anonymousMessages;
    setUp(() {
      repository = _FakeRepository();
      anonymousMessages = AnonymousMessages(repository);
    });
    test('Messages', () async {
      final emitted = [];
      anonymousMessages.messages.listen((event) {
        emitted.addAll(event);
      });
      repository.controller.add([
        Message('id:1', '1'),
        Message('id:2', '2'),
        Message('id:3', '3'),
      ]);
      await pumpEventQueue();
      expect(emitted.map((e) => e.id).toList(), ['id:1', 'id:2', 'id:3']);
    });

    test('Dispose.', () async {
      anonymousMessages.messages.listen(null);
      expect(repository.controller.hasListener, isTrue);

      anonymousMessages.dispose();
      await pumpEventQueue();
      expect(anonymousMessages.disposed, emitsInOrder([null, emitsDone]));
      expect(repository.controller.hasListener, isFalse);
    });
  });
}
