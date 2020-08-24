import 'dart:async';

import 'package:meta/meta.dart';
import 'package:reactive_component/reactive_component.dart';
import 'package:reactive_component/src/reactive_component.dart';
import 'package:reactive_component/src/resource_disposer.dart';
import 'package:test/test.dart';

void main() {
  group(ReactiveComponent, () {
    test('$_Counter example.', () async {
      final counter = _Counter();
      await expectLater(counter.count.first, completion(0));
      counter.increment();
      await pumpEventQueue();
      await expectLater(counter.count.first, completion(1));
      counter.dispose();
      await expectLater(counter.disposed.first, completion(null));
    });

    group('$_MultifunctionalCounter example.', () {
      _MultifunctionalCounter counter;

      setUp(() {
        counter = _MultifunctionalCounter(initialCount: 2);
      });

      tearDown(() {
        counter.dispose();
      });

      test('Add.', () async {
        counter.add(1);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(3));
      });

      test('Subtract.', () async {
        counter.subtract(1);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(1));
      });

      test('MultiplyBy.', () async {
        counter.multiplyBy(2);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(4));
      });
    });

    group('$_MultifunctionalCounterWithCounterInputEvent example.', () {
      _MultifunctionalCounterWithCounterInputEvent counter;

      setUp(() {
        counter = _MultifunctionalCounterWithCounterInputEvent(initialCount: 2);
      });

      tearDown(() {
        counter.dispose();
      });

      test(CounterInputEventType.add, () async {
        counter.counterInput(CounterInputEvent(CounterInputEventType.add, 1));
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(3));
      });

      test(CounterInputEventType.subtract, () async {
        counter
            .counterInput(CounterInputEvent(CounterInputEventType.subtract, 1));
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(1));
      });

      test(CounterInputEventType.multiply, () async {
        counter
            .counterInput(CounterInputEvent(CounterInputEventType.multiply, 2));
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(4));
      });
    });

    group('$_LoosenedMultiFunctionalCounter example.', () {
      _LoosenedMultiFunctionalCounter counter;

      setUp(() {
        counter = _LoosenedMultiFunctionalCounter(initialCount: 2);
      });

      tearDown(() {
        counter.dispose();
      });

      test('Add.', () async {
        counter.add(1);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(3));
      });

      test('Subtract.', () async {
        counter.subtract(1);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(1));
      });

      test('MultiplyBy.', () async {
        counter.multiplyBy(2);
        await pumpEventQueue();
        await expectLater(counter.count.first, completion(4));
      });
    });
  });

  group(_ComposedComponent, () {
    test('All components are disposed.', () async {
      final c = _ComposedComponent()..dispose();
      await expectLater(c.disposed.first, completion(null));
      await expectLater(c.testDisposedAll.first, completion(null));
    });
  });
}

class _MultifunctionalCounter with ReactiveComponent {
  _MultifunctionalCounter({@required int initialCount})
      : _initialCount = initialCount;

  final int _initialCount;

  ReactiveSink<int> _add;
  ReactiveSink<int> get add => _add ??= ReactiveSink((i) {
        _count.data = _count.data + i;
      }, disposer: disposer);

  ReactiveSink<int> _subtract;
  ReactiveSink<int> get subtract => _subtract ??= ReactiveSink((i) {
        _count.data = _count.data - i;
      }, disposer: disposer);

  ReactiveSink<int> _multiplyBy;
  ReactiveSink<int> get multiplyBy =>
      _multiplyBy ??= ReactiveSink(_multiply, disposer: disposer);

  Reactive<int> __count;
  Reactive<int> get _count =>
      __count ??= Reactive<int>(_initialCount, disposer: disposer);
  Stream<int> get count => _count.stream;

  void _multiply(int by) {
    _count.data = _count.data * by;
  }
}

enum CounterInputEventType { add, subtract, multiply }

class CounterInputEvent {
  CounterInputEvent(this.type, this.data);
  final CounterInputEventType type;
  final int data;
}

class _MultifunctionalCounterWithCounterInputEvent with ReactiveComponent {
  _MultifunctionalCounterWithCounterInputEvent({@required int initialCount})
      : _initialCount = initialCount;

  final int _initialCount;

  ReactiveSink<CounterInputEvent> _counterInput;
  ReactiveSink<CounterInputEvent> get counterInput =>
      _counterInput ??= ReactiveSink((event) {
        switch (event.type) {
          case CounterInputEventType.add:
            _count.data = _count.data + event.data;
            break;
          case CounterInputEventType.subtract:
            _count.data = _count.data - event.data;
            break;
          case CounterInputEventType.multiply:
            _multiply(event.data);
            break;
        }
      }, disposer: disposer);

  Reactive<int> __count;
  Reactive<int> get _count =>
      __count ??= Reactive<int>(_initialCount, disposer: disposer);
  Stream<int> get count => _count.stream;

  void _multiply(int by) {
    _count.data = _count.data * by;
  }
}

class _Counter with ReactiveComponent {
  VoidReactiveSink _increment;
  // FIXME: "this" is necessary here,
  // otherwise it will cause compile error:
  // " Error: Getter not found: 'disposer'.".
  // Dart SDK version: 2.10.0-7.0.dev (dev) (Mon Aug 10 22:32:08 2020 +0200) on "macos_x64"
  VoidReactiveSink get increment => _increment ??= VoidReactiveSink((_) {
        _count.data++;
      }, disposer: disposer);

  Reactive<int> __count;
  Reactive<int> get _count => __count ??= Reactive<int>(0, disposer: disposer);
  Stream<int> get count => _count.stream;
}

class _LoosenedMultiFunctionalCounter with ReactiveOutputComponent {
  _LoosenedMultiFunctionalCounter({@required int initialCount})
      : _initialCount = initialCount;

  final int _initialCount;

  Reactive<int> __count;
  Reactive<int> get _count =>
      __count ??= Reactive<int>(_initialCount, disposer: disposer);
  Stream<int> get count => _count.stream;

  void add(int count) {
    _count.data = _count.data + count;
  }

  void subtract(int count) {
    _count.data = _count.data - count;
  }

  void multiplyBy(int count) {
    _count.data = _count.data * count;
  }
}

class _ComposedComponent with ReactiveComponent {
  ReactiveSink<int> __aSink;
  ReactiveSink<int> get aSink =>
      __aSink ??= ReactiveSink<int>((event) {}, disposer: disposer);
  Reactive<int> __aReactiveInt;
  Reactive<int> get _aReactiveInt =>
      __aReactiveInt ??= Reactive<int>(0, disposer: disposer);
  _SubComponent __sub1;
  _SubComponent get _sub1 => __sub1 ??= _SubComponent(disposer: disposer);
  _SubComponent __sub2;
  _SubComponent get _sub2 => __sub2 ??= _SubComponent(disposer: disposer);
  _SubComponent __sub3;
  _SubComponent get _sub3 => __sub3 ??= _SubComponent(disposer: disposer);

  Stream<void> get testDisposedAll async* {
    await Future.wait([
      _sub1.disposed.first,
      _sub2.disposed.first,
      _sub3.disposed.first,
      aSink.disposed.first,
      _aReactiveInt.disposed.first
    ]);
    if ([_sub1, _sub2, _sub3].every((e) => e.isOwnADisposingTargetDisposed)) {
      yield null;
    }
  }
}

class _SubComponent with ReactiveComponent {
  _SubComponent({ResourceDisposer /*nullable*/ disposer}) {
    if (disposer != null) {
      delegateDisposingTo(disposer);
    }
  }

  final _aDisposeTarget = StreamController<int>();

  bool get isOwnADisposingTargetDisposed => _aDisposeTarget.isClosed;

  @override
  @protected
  Future<void> doDispose() async {
    await _aDisposeTarget.close();
  }
}
