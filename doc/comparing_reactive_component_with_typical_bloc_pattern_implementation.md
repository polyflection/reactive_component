# Comparing ReactiveComponent with typical BLoC pattern implementation

## Typical BLoC pattern implementation

```dart
import 'dart:async';

import 'package:rxdart/rxdart.dart';

class Counter {
  Counter(int initialCount)
      : _count = BehaviorSubject<int>.seeded(initialCount) {
    _incrementController.stream.listen((_) {
      _count.value++;
    });
  }

  final _incrementController = StreamController<void>();
  final BehaviorSubject<int> _count;

  Stream<int> get count => _count.stream;
  Sink<void> get increment => _incrementController.sink;

  void dispose() {
    _incrementController.close();
    _count.close();
  }
}
```

Implementing sink input is cumbersome. The implementation is scattered in four different places: "The private StreamController declaration", "The Sink public getter" "The input event handler usually in the constructor body", and "The sink closing in dispose method".

When a programmer want to see how an input data of a sink is handled, one have to look for it because the handler's implementation is separated in different place, usually in a constructor body. If it is nomal method decralation, a programmer can find the implementation immediately.

If more sinks are implemented, the codebase quickly become messy.

Handling a count state and the output stream is fortunately simple thanks to `BehaviorSubject` in RxDart. But it depends on RxDart anyway.

## ReactiveComponent

```dart
import 'package:reactive_component/reactive_component.dart';

class Counter with ReactiveComponent {
  Counter(this._initialCount);
  final int _initialCount;

  VoidReactiveSink _increment;
  VoidReactiveSink get increment => _increment ??= VoidReactiveSink((_) {
        _count.data++;
      }, disposer: disposer);

  Reactive<int> __count;
  Reactive<int> get _count =>
      __count ??= Reactive<int>(_initialCount, disposer: disposer);

  Stream<int> get count => _count.stream;
}
```

Unlike nomal sink implementation, ReactiveSink provides those implementations in one place. The StreamContller is bulit-in. The input event handler is declared at its constructor's parameter. The sink closing can also be declared at the constructor's named parameter "disposer:", which is usually about delegating to ReactiveComponent's disposer.

VoidReactiveSink is a ReactiveSink whose type parameter is "void". This is useful when an input data is always "null". The notation of adding data to the "VoidReactiveSink increment" is concise: "increment();", which is the shorthand notation of "increment.add(null);".

Reactive is slightly conciser than BehaviorSubject here, because its disposing can delegate to ReactiveComponent's disposer at the constructor's named parameter. In BehaviorSubject, its closing implementation is necessary in different place, usually in a dispose method.

## ReactiveComponent with "late final" in null-safety feature.

When null-safety feature become stable in Dart, one can utilize "late final" for lazily initializing ReactiveSink and Reactive, instead of "??=" technique.

```dart
import 'package:reactive_component/reactive_component.dart';

class Counter with ReactiveComponent {
  Counter(this._initialCount);
  final int _initialCount;

  late final VoidReactiveSink increment = VoidReactiveSink((_) {
        _count.data++;
      }, disposer: disposer);

  late final _count = Reactive<int>(_initialCount, disposer: disposer);

  Stream<int> get count => _count.stream;
}
```

Now the codebase is almost as concise as ChangeNotifier / ValueNotifier, without losing power of Stream.
