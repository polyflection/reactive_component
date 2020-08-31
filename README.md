# ReactiveComponent

A package that supports for creating stream-based reactive components, designed for simplicity, composability, flexibility.

With ReactiveComponent, it can compose models by taking advantage of Stream's powerful features in a concise codebase.

It is yet another state management package. It can be applied to any size of apps, from very small ones to large ones that usually have many complex component models.

When a ReactiveComponent wraps a domain model, it is described as implementing BLoC design pattern.

## A quick example: counter model.

```dart
/// [ReactiveComponent] is a unit that encapsulates its members
/// and publicizes only [Sink]s and [Stream]s.
class Counter with ReactiveComponent {
  Counter(this._initialCount);

  final int _initialCount;

  /// A special kind of [StreamSink] with its own single stream listener
  /// that handles the event data.
  VoidReactiveSink _increment;
  VoidReactiveSink get increment => _increment ??= VoidReactiveSink((_) {
        // Increments _count on a increment event is delivered.
        _count.data++;
      }, disposer: disposer);

  /// A [Reactive] int data as count state of this counter.
  ///
  /// [Reactive] is a special kind of [StreamController] that holds its latest
  /// stream data, and sends that as the first data to any new listener.
  Reactive<int> __count;
  Reactive<int> get _count =>
      __count ??= Reactive<int>(_initialCount, disposer: disposer);

  /// Publicize only the stream of [_count] to hide its data mutating
  /// and the other behaviors.
  /// It's a good point to transform the stream as necessary.
  Stream<int> get count => _count.stream;
}
```

In current Dart spec, a lazy initialization technique with "??=" let them access the other instance members at its callback functions.

When "null-safety" is available in a future Dart, thankfully the notation will be conciser as below,

```dart
class Counter with ReactiveComponent {
  Counter(this._initialCount);

  final int _initialCount;

  late final VoidReactiveSink increment = VoidReactiveSink((_) {
    _count.data++;
  }, disposer: disposer);

  late final Reactive<int> _count =
      Reactive<int>(_initialCount, disposer: disposer);

  Stream<int> get count => _count.stream;
}
```

For a complete Flutter counter app example with more detailed comments, see [Flutter counter example](example/flutter_counter/lib/main.dart).

## Examples

[There are two examples.](example/)

- Flutter Counter
- Composing Firebase

## Motivation

For simple app state management, [ChangeNotifier and ValueNotifier are sufficient](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), although they are not suitable for fairly large apps that have many complex models.

There are [the other options](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options), including BLoC / Rx family that leverages Stream.

BLoC pattern has some advantages. By allowing only Sinks and Streams to its public interface, it can control its data flow in a unified way with Stream that is one of the **core library of Dart**. It has very rich capabilities to control data flow with various stream transformers. For instance, "throttle" (throttling data), "switchMap" (canceling ongoing data handling when a new data is comming), "exhaustMap" (discarding all incoming data while handling a data), "combineLatest" (combining each latest data from many streams), and many others.

Also, Sink and Stream I/O is a natural point for providing some hook methods . One major usage would be logging the I/O events for describing the data flow.

One disadvantage of implementing Sink and Stream I/O is that [it can be cumbersome especially when implementing Sinks](doc/comparing_reactive_component_with_typical_bloc_pattern_implementation.md). Consequently, it is sometimes reasonable to loosen the constraint by not using Sinks, where a component loses its key capabilities on handling input data flow, which undermines composability.

Handling a model's state and the output stream is fortunately simple thanks to `BehaviorSubject` in RxDart. But it depends on RxDart anyway.

ReactiveComponent significantly reduces the boilerplate code of handling Sinks and Streams in a component model by its key features, while it still retains the flexibility to be partially composed of raw Streams as necessary ( e.g. when handling a Firestore's Stream ).

## Key features

### ReactiveComponent

```dart
class C with ReactiveComponent {}
```

ReactiveComponent is a unit for stream-based reactive programming, that
encapsulates its members and publicizes only [Sink] and [Stream] interfaces.

Deliberately, it is designed as mixin, so that a subclass can freely inherit from other class as necessary.

It can be a delegate to its instance members of [ReactiveResource]
via [disposer], for disposing of their resources together. [Reactive], [ReactiveSink], and [ReactiveComponent] itself are kind of [ReactiveResource].

For more explanations, see [the API documentation](https://pub.dev/documentation/reactive_component/latest/reactive_component/ReactiveComponent-mixin.html).

### Reactive

Reactive is a special kind of [StreamController] that holds its latest stream data, and sends that as the first data to any new listener.

Reactive stream is a multi-subscription stream, added at Dart version 2.9.0. This allows multiple subscription, and each listener to be treated as an individual stream.

Reactive's [data] can get and set [data] synchronously. When a new [data] is set, it will be sent to all listeners of Reactive's stream immediately.

```dart
final aReactiveInt = Reactive<int>(0, disposer: null);

aReactiveInt.data = 1;
aReactiveInt.stream.listen(print); // prints 1 2 3.
aReactiveInt.data = 2;
aReactiveInt.stream.listen(print); // prints 2 3.
aReactiveInt.data = 3;
aReactiveInt.stream.listen(print); // prints 3.
print(aReactiveInt.data); // prints 3.
```

For more explanations, including "Disposing its resource" and "Reactive data should be encapsulated in a ReactiveComponent", see [the API documentation](https://pub.dev/documentation/reactive_component/latest/reactive_component/Reactive-class.html).

### ReactiveSink

ReactiveSink is a special kind of [StreamSink] with its own single stream listener that handles the event data.
An event stream can be transformed by transform callback function
passed at the constructor.

```dart
var i = 0;

final sink = ReactiveSink<int>((event) {
  i = i + event;
}, transform: (stream) => stream.map((e) => e * 2), disposer: null);

sink(1); // Shorthand notation of "sink.add(1);".

Future.microtask(() {
  print(i); // prints 2.
});
```

To save CPU and memory usage, the stream is lazily listened when a first
data is added to the sink, or [HandleSubscription] is passed to
its constructor.

For more explanations, including "Disposing its resource", see [the API documentation](https://pub.dev/documentation/reactive_component/latest/reactive_component/ReactiveSink-class.html).

### Sub components

ReactiveComponent can be nesting. The documentation will be added.

See [Sub components pattern](doc/sub_components_pattern.md).

### Platform agnostic

ReactiveComponent is a platform-agnostic pure Dart package. It works in any platform, such as a Flutter app, an AngularDart app, a console app, or a Dart package.

## Status

The core features are almost stable. A few APIs will likely change. More features are planned, such as a hook API for both ReactiveSink and Reactive, some static analysis supports.

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/polyflection/reactive_component/issues).
