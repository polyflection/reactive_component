# ReactiveComponent

A Dart package for stream-based reactive programming, designed to support simplicity, composability, flexibility.

```dart
class Counter with ReactiveComponent {
  late final VoidReactiveSink increment = VoidReactiveSink((_) {
    _count.data++;
  }, disposer: disposer);

  Stream<int> get count => _count.stream;

  late final _count = Reactive<int>(0, disposer: disposer);
}
```

```dart
final counter = Counter();
// Initial data is delivered immediately, like BehaviorSubject.
await expectLater(counter.count.first, completion(0));
// Add null data to a Sink named "increment".
counter.increment();
await pumpEventQueue();
// Next data is delivered.
await expectLater(counter.count.first, completion(1));
// Multiple listeners are allowed, and latest data is delivered on listen immediately.
await expectLater(counter.count.first, completion(1));
// Add null data to a Sink named "dispose".
// The all resources of the component will be disposed of together.
counter.dispose();
// A disposed stream.
await expectLater(counter.disposed.first, completion(null));
```

It hides the complexity and pitfall of Stream and Sink, which results in reducing difficulty and boilerplate code significantly. While it can always be composed of raw Stream and Sink when it is necessary ( e.g. Firestore's Stream ).

A component disposing action can delegate to other components so that component resources should always be disposed of together.

ReactiveComponent is a platform-agnostic pure Dart package. It works in any platform, such as a Flutter app, an AngularDart app, a console app, or a Dart package.

## BLoC pattern support.

When a ReactiveComponent wraps a domain model ( = business logic ), only with a bunch of public ReactiveSink and Reactive, it can be called as "BLoC".

## Status

This is the initial release. Non non-nullable version will be added soon.

Documents and more test code should be added. Some APIs will likely change. More features are planned, such as logging for Sink / Stream, static analysis supports.
