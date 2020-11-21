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
        final sink = ReactiveSink<int>((_) {}, onCancel: () {
          onCancelIsCalled = true;
        }, disposer: null);
        sink(0);
        sink.close();
        await pumpEventQueue();
        expect(onCancelIsCalled, isTrue);
      });
    });

    test(
        'Pause and resume by event StreamSubscription, '
        'which can be handled via HandleSubscription callback.', () async {
      late StreamSubscription<int> eventSubscription;
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
      late StreamSubscription<int> eventSubscription;

      final sink = ReactiveSink<int>((_) {}, handleSubscription: (s) {
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
      late ReactiveSink<int> sink;
      late ResourceDisposer disposer;
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
        late StreamSubscription<int> subscription;
        sink = ReactiveSink<int>((event) {}, disposer: disposer,
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
      }, skip: true);
    });

    group('Not delegating disposing', () {
      late ReactiveSink<int> sink;

      setUp(() {
        sink = ReactiveSink<int>((event) {}, disposer: null);
      });

      test('Dispose by dispose()', () async {
        sink.dispose();
        await pumpEventQueue();
        await _expectSinkWillBeDisposed(sink);
      });

      test('Dispose by dispose() on pause', () async {
        late StreamSubscription<int> subscription;
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
      final sink = ReactiveSink<int>((_) {}, onDispose: () {
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

  group('ReactiveEventSink', () {
    test('is kind of EventSink.', () {
      expect(ReactiveEventSink((_) {}, disposer: null) is EventSink, isTrue);
    });
    test('is kind of ReactiveSink.', () {
      expect(ReactiveEventSink((_) {}, disposer: null) is ReactiveSink, isTrue);
    });

    group('addError.', () {
      test('addError adds an error.', () async {
        var onDataReached = false;
        var onErrorReached = false;
        final sink = ReactiveEventSink((_) {
          onDataReached = true;
        }, onError: (error, stackTrace) {
          onErrorReached = true;
        }, disposer: null);
        sink.addError(Exception('exception.'));
        await pumpEventQueue();
        expect(onDataReached, isFalse);
        expect(onErrorReached, isTrue);
      });

      test('After disposed, addError is ignored.', () async {
        var onDataReached = false;
        var onErrorReached = false;
        final sink = ReactiveEventSink((_) {
          onDataReached = true;
        }, onError: (_, __) {
          onErrorReached = true;
        }, disposer: null);
        sink.dispose();
        await sink.disposed;
        sink.addError(Exception('exception.'));
        await pumpEventQueue();
        expect(onDataReached, isFalse);
        expect(onErrorReached, isFalse);
      });

      test('Listening lazily.', () {
        final sink = ReactiveEventSink((_) {},
            onError: (error, stackTrace) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNull);
        sink.addError(Error());
        expect(sink.eventStreamSubscription, isNotNull);
      });
    });
  });

  group('VoidReactiveEventSink', () {
    test('is kind of EventSink.', () {
      expect(VoidReactiveEventSink(() {}, disposer: null) is EventSink, isTrue);
    });
    test('is kind of VoidReactiveSink.', () {
      expect(VoidReactiveEventSink(() {}, disposer: null) is VoidReactiveSink,
          isTrue);
    });

    group('addError.', () {
      test('addError adds an error.', () async {
        var onDataReached = false;
        var onErrorReached = false;
        final sink = VoidReactiveEventSink(() {
          onDataReached = true;
        }, onError: (_, __) {
          onErrorReached = true;
        }, disposer: null);
        sink.addError(Exception('exception.'));
        await pumpEventQueue();
        expect(onDataReached, isFalse);
        expect(onErrorReached, isTrue);
      });

      test('After disposed, addError is ignored.', () async {
        var onDataReached = false;
        var onErrorReached = false;
        final sink = VoidReactiveEventSink(() {
          onDataReached = true;
        }, onError: (_, __) {
          onErrorReached = true;
        }, disposer: null);
        sink.dispose();
        await sink.disposed;
        sink.addError(Exception('exception.'));
        await pumpEventQueue();
        expect(onDataReached, isFalse);
        expect(onErrorReached, isFalse);
      });

      test('Listening lazily.', () {
        final sink =
            VoidReactiveEventSink(() {}, onError: (_, __) {}, disposer: null);
        expect(sink.eventStreamSubscription, isNull);
        sink.addError(Error());
        expect(sink.eventStreamSubscription, isNotNull);
      });
    });
  });

  group('ReactiveStreamSink', () {
    test('is kind of StreamSink.', () {
      expect(ReactiveStreamSink((_) {}, disposer: null) is StreamSink, isTrue);
    });
    test('is kind of ReactiveEventSink.', () {
      expect(ReactiveStreamSink((_) {}, disposer: null) is ReactiveEventSink,
          isTrue);
    });

    group('addStream.', () {
      test('addStream adds a stream.', () async {
        var dataList = [];
        final sink = ReactiveStreamSink<int>((e) {
          dataList.add(e);
        }, disposer: null);
        await sink.addStream(Stream.fromIterable([1, 2, 3]));
        await pumpEventQueue();
        expect(dataList, orderedEquals([1, 2, 3]));
      });

      test('After disposed, addStream is ignored.', () async {
        var dataList = [];
        final sink = ReactiveStreamSink<int>((e) {
          dataList.add(e);
        }, disposer: null);
        sink.dispose();
        await sink.disposed;
        await sink.addStream(Stream.fromIterable([1, 2, 3]));
        await pumpEventQueue();
        expect(dataList, isEmpty);
      });
    });

    test('Listening lazily.', () {
      final sink = ReactiveStreamSink<int>((_) {}, disposer: null);
      expect(sink.eventStreamSubscription, isNull);
      sink.addStream(Stream.value(0));
      expect(sink.eventStreamSubscription, isNotNull);
    });

    group('Dispose.', () {
      group('Delegating disposing.', () {
        late ReactiveStreamSink<int> sink;
        late ResourceDisposer disposer;
        var isEventHandled = false;

        setUp(() {
          isEventHandled = false;
          disposer = ResourceDisposer(doDispose: null, onDispose: null);
          sink = ReactiveStreamSink<int>((_) {
            isEventHandled = true;
          }, disposer: disposer);
        });

        test('Dispose by delegated disposer', () async {
          disposer.dispose();
          await pumpEventQueue();
          await _expectStreamSinkWillBeDisposed(sink);
        });

        test('A event is discarded from right after a dispose is called.',
            () async {
          disposer.dispose();
          sink.add(0);
          await pumpEventQueue();
          expect(isEventHandled, isFalse);
          await _expectStreamSinkWillBeDisposed(sink);
        });

        test('Dispose by dispose() on pause', () async {
          late StreamSubscription<int> subscription;
          sink = ReactiveStreamSink<int>((event) {}, disposer: disposer,
              handleSubscription: (s) {
            subscription = s;
          });
          subscription.pause();
          sink.dispose();
          await pumpEventQueue();
          await _expectStreamSinkWillBeDisposed(sink);
        });

        test('Can not dispose by own dispose(), (planned on a future version)',
            () async {
          sink.dispose();
          await pumpEventQueue();
          await expectLater(
              () =>
                  sink.disposed.first.timeout(const Duration(milliseconds: 1)),
              throwsA(TypeMatcher<TimeoutException>()),
              reason: 'Disposing action has been delegated.');
        }, skip: true);
      });

      group('Not delegating disposing', () {
        late ReactiveStreamSink<int> sink;

        setUp(() {
          sink = ReactiveStreamSink<int>((event) {}, disposer: null);
        });

        test('Dispose by dispose()', () async {
          sink.dispose();
          await pumpEventQueue();
          await _expectStreamSinkWillBeDisposed(sink);
        });

        test('Dispose by dispose() on pause', () async {
          late StreamSubscription<int> subscription;
          sink = ReactiveStreamSink<int>((event) {}, disposer: null,
              handleSubscription: (s) {
            subscription = s;
          });
          subscription.pause();
          sink.dispose();
          await pumpEventQueue();
          await _expectStreamSinkWillBeDisposed(sink);
        });
      });
    });
  });

  group('VoidReactiveStreamSink.', () {
    test('is kind of StreamSink.', () {
      expect(
          VoidReactiveStreamSink(() {}, disposer: null) is StreamSink, isTrue);
    });

    test('is kind of VoidReactiveEventSink.', () {
      expect(
          VoidReactiveStreamSink(() {}, disposer: null)
              is VoidReactiveEventSink,
          isTrue);
    });

    group('addStream.', () {
      test('addStream adds a stream.', () async {
        var dataReachedCount = 0;
        final sink = VoidReactiveStreamSink(() {
          dataReachedCount++;
        }, disposer: null);
        await sink.addStream(Stream.fromIterable([null, 1, 'a']));
        await pumpEventQueue();
        expect(dataReachedCount, 3);
      });

      test('After disposed, addStream is ignored.', () async {
        var dataReachedCount = 0;
        final sink = VoidReactiveStreamSink(() {
          dataReachedCount++;
        }, disposer: null);
        sink.dispose();
        await sink.disposed;
        await sink.addStream(Stream.fromIterable([null, 1, 'a']));
        await pumpEventQueue();
        expect(dataReachedCount, 0);
      });
    });

    test('Listening lazily.', () {
      final sink = VoidReactiveStreamSink(() {}, disposer: null);
      expect(sink.eventStreamSubscription, isNull);
      sink.addStream(Stream.value(0));
      expect(sink.eventStreamSubscription, isNotNull);
    });
  });
}

Future<void> _expectSinkWillBeDisposed(ReactiveSink<int> sink) async {
  await expectLater(sink.disposed.first, completion(null));
  await expectLater(sink.testSinkDone(), completion(null));
}

Future<void> _expectStreamSinkWillBeDisposed(
    ReactiveStreamSink<int> sink) async {
  await expectLater(sink.disposed.first, completion(null));
  await expectLater(sink.done, completion(null));
}
