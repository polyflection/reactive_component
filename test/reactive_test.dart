import 'dart:async';

import 'package:reactive_component/reactive_component.dart';
import 'package:reactive_component/src/resource_disposer.dart';
import 'package:test/test.dart';

void main() {
  group('Reactive', () {
    late Reactive<int> aReactiveInt;

    setUp(() {
      aReactiveInt = Reactive<int>(0, disposer: null);
    });

    group('Get and set a data.', () {
      tearDown(() async {
        await aReactiveInt.close();
      });

      test('Get data.', () {
        expect(aReactiveInt.data, 0);
      });

      test('Set data.', () {
        aReactiveInt.data++;
        expect(aReactiveInt.data, 1);
      });
    });

    group('Data streams.', () {
      group('Listen data streams.', () {
        test('On listen, a listen will receive a latest data.', () async {
          aReactiveInt.stream.listen(expectAsync1((data) {
            expect(data, 0);
          }, count: 1));
          await aReactiveInt.close();
        });
        test('Reactive stream allows multiple listener.', () async {
          aReactiveInt.stream.listen(expectAsync1((data) {
            expect(data, 0);
          }, count: 1));
          aReactiveInt.stream.listen(expectAsync1((data) {
            expect(data, 0);
          }, count: 1));
          aReactiveInt.stream.listen(expectAsync1((data) {
            expect(data, 0);
          }, count: 1));
          await aReactiveInt.close();
        });
        test('When a new data is set, each stream listener will receive it.',
            () async {
          expect(aReactiveInt.stream.toList(), completion([0, 1, 2]));
          expect(aReactiveInt.stream.toList(), completion([0, 1, 2]));
          expect(aReactiveInt.stream.toList(), completion([0, 1, 2]));
          aReactiveInt.data++;
          aReactiveInt.data++;
          await aReactiveInt.close();
        });
        group('Set onListen callback.', () {
          test('Set it by a constructor.', () async {
            var i = 0;
            aReactiveInt = Reactive<int>(0, onListen: () {
              i = aReactiveInt.data + 1;
            }, disposer: null);
            aReactiveInt.stream.listen(expectAsync1((data) {
              expect(i, 1);
            }, count: 1));
            await aReactiveInt.close();
          });
          test('Set it by a setter.', () async {
            var i = 0;
            aReactiveInt = Reactive<int>(0, disposer: null);
            aReactiveInt.onListen = () {
              i = aReactiveInt.data + 1;
            };
            aReactiveInt.stream.listen(expectAsync1((data) {
              expect(i, 1);
            }, count: 1));
            await aReactiveInt.close();
          });
        });
      });
    });

    group('Add data to streams.', () {
      test('By a Reactive.', () {});
      test('By a sink of Reactive.', () {});
    });
    group('Transform streams.', () {
      test('Transform each stream.', () async {
        expect(aReactiveInt.stream.toList(), completion([0, 1, 2]));
        expect(aReactiveInt.stream.map((e) => e * 2).toList(),
            completion([0, 2, 4]));
        expect(
            aReactiveInt.stream
                .expand((e) => [e, e])
                .where((e) => e >= 1)
                .toList(),
            completion([1, 1, 2, 2]));
        aReactiveInt.data++;
        aReactiveInt.data++;
        await aReactiveInt.close();
      });
    });

    group('Cancel streams.', () {
      test('Cancel, then isCanceled.', () async {
        expect(aReactiveInt.hasListener, isFalse);
        final subscription1 = aReactiveInt.stream.listen(null);
        expect(aReactiveInt.hasListener, isTrue);
        final subscription2 = aReactiveInt.stream.listen(null);
        final subscription3 = aReactiveInt.stream.listen(null);
        await subscription1.cancel();
        await subscription2.cancel();
        expect(aReactiveInt.hasListener, isTrue);
        await subscription3.cancel();
        expect(aReactiveInt.hasListener, isFalse);
      });

      group('Set onCancel callback.', () {
        test('Set it by a constructor.', () {});
        test('Set it by a setter.', () {});
      }, skip: true);
    });

    group('Pause streams.', () {
      test('Pause, then isPaused.', () {});
      group('Set onPause callback.', () {
        test('Set it by a constructor.', () {});
        test('Set it by a setter.', () {});
      });
    }, skip: true);

    group('Resume streams.', () {
      test('Resume, then isPaused.', () {});
      group('Set onResume callback.', () {
        test('Set it by a constructor.', () {});
        test('Set it by a setter.', () {});
      });
    }, skip: true);

    group('Error streams.', () {
      group('AddError.', () {
        test('By a Reactive.', () {});
        test('By a sink of Reactive.', () {});
      });
    }, skip: true);

    group('HasListener.', () {});
    group('AddStream.', () {
      test('By a Reactive.', () {});
      test('By a sink of Reactive.', () {});
    }, skip: true);

    group('Sink Type.', () {
      test('A sink of Reactive can not cast to Reactive.', () {
        expect(() => aReactiveInt.sink as Reactive,
            throwsA(TypeMatcher<TypeError>()));
      });
    });

    group('Dispose.', () {
      group('Delegating disposing.', () {
        late Reactive<int> aReactiveInt;
        late ResourceDisposer disposer;

        setUp(() {
          disposer = ResourceDisposer(doDispose: null, onDispose: null);
          aReactiveInt = Reactive<int>(0, disposer: disposer);
        });

        test('Dispose by delegated disposer', () async {
          disposer.dispose();
          await pumpEventQueue();
          await expectLater(aReactiveInt.disposed.first, completion(null));
          await expectLater(aReactiveInt.done, completion(null));
        });

        test('Can not dispose by own dispose(), (planned on a future version)',
            () async {
          aReactiveInt.dispose();
          await pumpEventQueue();
          await expectLater(
              () => aReactiveInt.disposed.first
                  .timeout(const Duration(milliseconds: 1)),
              throwsA(TypeMatcher<TimeoutException>()));
          await expectLater(
              () => aReactiveInt.done.timeout(const Duration(milliseconds: 1)),
              throwsA(TypeMatcher<TimeoutException>()));
        }, skip: true);
      });

      group('Not delegating disposing', () {
        late Reactive<int> aReactiveInt;

        setUp(() {
          aReactiveInt = Reactive<int>(0, disposer: null);
        });

        test('Can dispose by dispose()', () async {
          aReactiveInt.dispose();
          await pumpEventQueue();
          await expectLater(aReactiveInt.disposed.first, completion(null));
          await expectLater(aReactiveInt.done, completion(null));
        });
      });

      test('OnDispose callback.', () async {
        var onDisposeCalled = false;
        final aReactiveInt = Reactive<int>(0, onDispose: () {
          onDisposeCalled = true;
        }, disposer: null);
        aReactiveInt.dispose();
        await pumpEventQueue();
        expect(onDisposeCalled, isTrue);
      });
    });
  });
}
