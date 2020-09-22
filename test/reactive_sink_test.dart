import 'dart:async';

import 'package:reactive_component/reactive_component.dart';
import 'package:reactive_component/src/resource_disposer.dart';
import 'package:test/test.dart';

void main() {
  group('ReactiveSink', () {
    group('Adding event.', () {
      test('Add.', () async {
        var i = 0;
        final sink = ReactiveSink<int>((event) {
          i = i + event;
        }, disposer: null);
        sink.add(1);
        await pumpEventQueue();
        expect(i, 1);
      });
      test('Call to add.', () async {
        var i = 0;
        final sink = ReactiveSink<int>((event) {
          i = i + event;
        }, disposer: null);
        sink(1);
        await pumpEventQueue();
        expect(i, 1);
      });
    });

    test('Transforms.', () async {
      var i = 0;
      final sink = ReactiveSink<int>((event) {
        i = i + event;
      }, transform: (stream) => stream.map((e) => e * 2), disposer: null);
      sink(1);
      await pumpEventQueue();
      expect(i, 2);
    });

    group('Listening lazily.', () {
      test('On add.', () {
        final sink = ReactiveSink<int>((event) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNull);
        sink.add(1);
        expect(sink.eventStreamSubscription, isNotNull);
      });
      test('On addStream.', () async {
        final sink = ReactiveStreamSink<int>((event) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNull);
        await sink.addStream(Stream.value(1));
        expect(sink.eventStreamSubscription, isNotNull);
      });
      test('On addError.', () async {
        final sink = ReactiveEventSink<int>((event) {},
            onError: (e, s) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNull);
        sink.addError(Error());
        expect(sink.eventStreamSubscription, isNotNull);
      });
      test('On handleSubscription.', () async {
        final sink = ReactiveSink<int>((event) {},
            handleSubscription: (s) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNotNull);
      });
    });

    group('Callbacks', () {
      group('OnError', () {}, skip: true);
      group('CancelOnError', () {}, skip: true);
      group('OnPause', () {}, skip: true);
      group('OnResume', () {}, skip: true);
      group('OnCancel', () {}, skip: true);
      test('Invoking close with listening, onCancel is called.', () async {
        var onCancelIsCalled = false;
        final sink = ReactiveSink<int>((event) {}, onCancel: () {
          onCancelIsCalled = true;
        }, disposer: null);
        sink(0);
        await sink.close();
        expect(onCancelIsCalled, isTrue);
      });
    });

    test(
        'Pause and resume by event StreamSubscription, '
        'which can be handled via HandleSubscription callback.', () async {
      StreamSubscription<int> eventSubscription;
      var i = 0;
      final sink = ReactiveSink<int>((event) {
        i = i + event;
      }, handleSubscription: (s) {
        eventSubscription = s;
      }, disposer: null);

      eventSubscription.pause();
      expect(eventSubscription.isPaused, isTrue);
      sink(1);
      expect(i, 0, reason: 'The event stream paused.');
      eventSubscription.resume();
      await pumpEventQueue();
      expect(i, 1, reason: 'The event Stream resumed.');

      // Again.
      eventSubscription.pause();
      expect(eventSubscription.isPaused, isTrue);
      sink(1);
      expect(i, 1, reason: 'The event stream paused.');
      eventSubscription.resume();
      await pumpEventQueue();
      expect(i, 2, reason: 'The event Stream resumed.');
    });

    test('Cancel subscription.', () async {
      var onDoneIsCalled = false;
      StreamSubscription<int> eventSubscription;

      final sink = ReactiveSink<int>((event) {}, handleSubscription: (s) {
        eventSubscription = s;
      }, disposer: null);

      await eventSubscription.cancel();
      await pumpEventQueue();
      expect(onDoneIsCalled, isFalse,
          reason: 'by eventSubscription.cancel(), onDone callback is not called'
              'because it is how StreamController handles onDone callback.');

      sink.dispose();
      await pumpEventQueue();
      expect(onDoneIsCalled, isFalse,
          reason: 'After eventSubscription.cancel(), even sink.close(),'
              'onDone callback is not called because'
              'it is how StreamController handles onDone callback.');
    });
  });

  group('Dispose.', () {
    group('Delegating disposing.', () {
      ReactiveStreamSink<int> sink;
      ResourceDisposer disposer;
      var isEventHandled = false;

      setUp(() {
        isEventHandled = false;
        disposer = ResourceDisposer(doDispose: null, onDispose: null);
        sink = ReactiveSink<int>((_) {
          isEventHandled = true;
        }, disposer: disposer);
      });

      test('Dispose by delegated disposer', () async {
        disposer.dispose();
        await pumpEventQueue();
        await _expectSinkWillBeDisposed(sink);
      });

      test('A event is discarded from right after a dispose is called.',
          () async {
        disposer.dispose();
        sink.add(0);
        await pumpEventQueue();
        expect(isEventHandled, isFalse);
        await _expectSinkWillBeDisposed(sink);
      });

      test('Dispose by dispose() on pause', () async {
        StreamSubscription<int> subscription;
        sink = ReactiveStreamSink<int>((event) {}, disposer: disposer,
            handleSubscription: (s) {
          subscription = s;
        });
        subscription.pause();
        sink.dispose();
        await pumpEventQueue();
        await _expectSinkWillBeDisposed(sink);
      });

      test('Can not dispose by own dispose(), (planned on a future version)',
          () async {
        sink.dispose();
        await pumpEventQueue();
        await expectLater(
            () => sink.disposed.first.timeout(const Duration(milliseconds: 1)),
            throwsA(TypeMatcher<TimeoutException>()),
            reason: 'Disposing action has been delegated.');
        await expectLater(
            () => sink.done.timeout(const Duration(milliseconds: 1)),
            throwsA(TypeMatcher<TimeoutException>()),
            reason: 'Disposing action has been delegated.');
      }, skip: true);
    });

    group('Not delegating disposing', () {
      ReactiveSink<int> sink;

      setUp(() {
        sink = ReactiveSink<int>((event) {}, disposer: null);
      });

      test('Dispose by dispose()', () async {
        sink.dispose();
        await pumpEventQueue();
        await _expectSinkWillBeDisposed(sink);
      });

      test('Dispose by dispose() on pause', () async {
        StreamSubscription<int> subscription;
        sink = ReactiveSink<int>((event) {}, disposer: null,
            handleSubscription: (s) {
          subscription = s;
        });
        subscription.pause();
        sink.dispose();
        await pumpEventQueue();
        await _expectSinkWillBeDisposed(sink);
      });
    });

    test('OnDispose callback.', () async {
      var onDisposeCalled = false;
      final sink = ReactiveSink<int>((event) {}, onDispose: () {
        onDisposeCalled = true;
      }, disposer: null);
      sink.dispose();
      await pumpEventQueue();
      expect(onDisposeCalled, isTrue);
    });
  });

  group(VoidReactiveSink, () {
    test('Add null by call.', () async {
      var reached = false;
      final sink = VoidReactiveSink(() {
        reached = true;
      }, disposer: null);
      sink();
      await pumpEventQueue();
      expect(reached, isTrue);
    });
  });
}

Future<void> _expectSinkWillBeDisposed(ReactiveStreamSink<int> sink) async {
  await expectLater(sink.disposed.first, completion(null));
  await expectLater(sink.done, completion(null));
  await expectLater(sink.testSinkDone(), completion(null));
}
