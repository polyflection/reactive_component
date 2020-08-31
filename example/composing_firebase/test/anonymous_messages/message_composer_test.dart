import 'package:composing_firebase/anonymous_messages/message_composer.dart';
import 'package:composing_firebase/anonymous_messages/messages_repository.dart';
import 'package:composing_firebase/authentication/user.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockRepository extends Mock implements MessagesAddingRepository {}

void main() {
  group(MessageComposer, () {
    _MockRepository repository;
    MessageComposer messageComposer;
    setUp(() {
      repository = _MockRepository();
      messageComposer = MessageComposer(repository, AnonymousUser('anId'));
    });

    group('Form and updateMessage.', () {
      test('Initial form.', () async {
        final form = await messageComposer.form.first;
        expect(form.isValid, isFalse);
        expect(form.message, '');
      });
      test('updateMessage.', () async {
        messageComposer.updateMessageText('something');
        final form = await messageComposer.form.first;
        expect(form.isValid, isTrue);
        expect(form.message, 'something');
      });
      test('updateMessage with empty text.', () async {
        messageComposer.updateMessageText('');
        final form = await messageComposer.form.first;
        expect(form.isValid, isFalse);
        expect(form.message, '');
      });
    });

    group('CanSend, Sending and the result streams.', () {
      group('When a composing message is valid.', () {
        setUp(() async {
          messageComposer.updateMessageText('something');
          await pumpEventQueue();
        });
        test('A message is sent.', () async {
          messageComposer.send();
          expect(messageComposer.canSend, emitsInOrder([true, false]));
          expect(messageComposer.sent, emits(null));
          expect(messageComposer.errorMessage, neverEmits(anything));
          await pumpEventQueue();
          verify(repository.add(any, any)).called(1);
          messageComposer.dispose();
        });
      });

      group('When a composing message is not valid.', () {
        setUp(() async {
          messageComposer.updateMessageText('');
          await pumpEventQueue();
        });
        test('A message is not sent.', () async {
          messageComposer.send();
          expect(messageComposer.canSend, emits(false));
          expect(messageComposer.sent, neverEmits(anything));
          expect(messageComposer.errorMessage, emits(anything));
          await pumpEventQueue();
          verifyNever(repository.add(any, any));
          messageComposer.dispose();
        });
      });
    });

    test('Dispose.', () async {
      messageComposer.dispose();
      expect(messageComposer.disposed, emitsInOrder([null, emitsDone]));
    });
  });
}
