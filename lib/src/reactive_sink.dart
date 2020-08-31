import 'dart:async';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'reactive_resource.dart';
import 'resource_disposer.dart';
import 'sinks.dart';
import 'typedef.dart';

/// A special kind of [StreamSink] with its own single stream listener
/// that handles the event data.
///
/// An event stream can be transformed by [_Transform] callback function
/// passed at the constructor.
///
/// # Example.
///
/// ```
/// var i = 0;
///
/// final sink = ReactiveSink<int>((event) {
///   i = i + event;
/// }, transform: (stream) => stream.map((e) => e * 2), disposer: null);
///
/// sink(1); // Shorthand notation of "sink.add(1);".
///
/// Future.microtask(() {
///   print(i); // prints 2.
/// });
/// ```
///
/// To save CPU and memory usage, the stream is lazily listened when a first
/// data is added to the sink, or [HandleSubscription] is passed to
/// its constructor.
///
/// # Disposing its resource, or delegating to other [ReactiveResource].
///
/// ReactiveSink is a kind of [ReactiveResource], which provides
/// resource disposing action by [dispose] sink.
/// [dispose] action can be delegated to other [ReactiveResource],
/// typically a [ReactiveComponent].
/// See [ReactiveComponent] for more explanation about delegating [dispose].
//
// TODO: It should be better to split up ReactiveSink into 3 classes,
// as ReactiveSink, ReactiveEventSink, ReactiveStreamSink
// (that will be breaking change).
class ReactiveSink<E> with ReactiveResource implements StreamSink<E> {
  /// Creates a [ReactiveSink] with its event stream handler.
  ///
  /// It optionally pass [disposer] for delegating
  /// its own resource disposing.
  ///
  /// [onDispose] callback will be certainly called only once on [dispose]
  /// called.
  ///
  /// [onError], [cancelOnError] are callbacks to be set on listening
  /// the event stream.
  ///
  /// [onListen], [onPause], [onResume], [onCancel]
  /// are callbacks to be set to the event stream controller.
  ///
  /// [handleSubscription] is the callback to get the [StreamSubscription] of
  /// the event stream.
  ReactiveSink(this._onEvent,
      {_Transform<E> /*nullable*/ transform,
      @required ResourceDisposer /*nullable*/ disposer,
      VoidCallback /*nullable*/ onDispose,
      _OnError /*nullable*/ onError,
      bool /*nullable*/ cancelOnError,
      VoidCallback /*nullable*/ onListen,
      VoidCallback /*nullable*/ onPause,
      VoidCallback /*nullable*/ onResume,
      VoidCallback /*nullable*/ onCancel,
      HandleSubscription<E> /*nullable*/ handleSubscription})
      : _transform = transform,
        _onDispose = onDispose,
        _onError = onError,
        _cancelOnError = cancelOnError,
        _onListen = onListen,
        _onPause = onPause,
        _onResume = onResume,
        _onCancel = onCancel {
    if (disposer != null) {
      delegateDisposingTo(disposer);
    }
    if (handleSubscription != null) {
      _listenOnce();
      handleSubscription(eventStreamSubscription);
    }
  }

  /// Adds [event] to the sink.
  ///
  /// Unlike [Sink], added event is ignored after a call to [dispose],
  /// which is the [Sink] version of [ReactiveSink]'s [close].
  void call(E event) {
    // This avoids "Bad state: Cannot add event after closing" error.
    if (isDisposeEventSent) return;

    _listenOnce();
    _eventStreamController.add(event);
  }

  /// Alias method of [call].
  @override
  void add(E event) {
    call(event);
  }

  @override
  Future<void> addStream(Stream<E> stream) async {
    if (isDisposeEventSent) return;

    _listenOnce();
    return _eventStreamController.addStream(stream);
  }

  @override
  void addError(Object error, [StackTrace /*nullable*/ stackTrace]) {
    if (isDisposeEventSent) return;

    _listenOnce();
    _eventStreamController.addError(error, stackTrace);
  }

  @override
  Future<void> close() async {
    if (isDisposeEventSent) return;

    dispose();
    return done;
  }

  @override
  Future<void> get done => disposed.first;

  /// A [Future] that completes when [_eventStreamController] is done.
  ///
  /// Only visible for testing.
  @visibleForTesting
  Future<void> testSinkDone() {
    return _eventStreamController.done;
  }

  @override
  @protected
  void onDispose() {
    _onDispose?.call();
  }

  @override
  @protected
  Future<void> doDispose() async {
    await _doCloseSink();
  }

  final _OnEvent<E> _onEvent;
  final _Transform<E> /*nullable*/ _transform;
  final VoidCallback /*nullable*/ _onDispose;
  final _OnError /*nullable*/ _onError;
  final bool /*nullable*/ _cancelOnError;
  final VoidCallback /*nullable*/ _onListen;
  final VoidCallback /*nullable*/ _onPause;
  final VoidCallback /*nullable*/ _onResume;
  final VoidCallback /*nullable*/ _onCancel;

  StreamController<E> __eventStreamController;
  StreamController<E> get _eventStreamController =>
      __eventStreamController ??= StreamController<E>(
          onListen: _onListen,
          onPause: _onPause,
          onResume: _onResume,
          onCancel: _onCancel);

  /// A event stream subscription.
  ///
  /// Only visible for testing.
  @visibleForTesting
  /*late final*/ StreamSubscription<E> /*nullable*/ eventStreamSubscription;

  /// Closes [_eventStreamController]'s sink.
  Future<void> _doCloseSink() async {
    if (_eventStreamController.isClosed) return;

    if (_eventStreamController.hasListener) {
      return eventStreamSubscription.cancel();
    } else {
      if (eventStreamSubscription == null) {
        // If a stream is not listened, a sink will not be done.
        // So listening by "drain" here is necessary.
        unawaited(_eventStreamController.stream.drain());
      }
      return _eventStreamController.close();
    }
  }

  void _listenOnce() {
    if (eventStreamSubscription != null) return;

    eventStreamSubscription =
        (_transform?.call(_eventStreamController.stream) ??
                _eventStreamController.stream)
            .listen(_onEvent, onError: _onError, cancelOnError: _cancelOnError);
  }
}

/// [ReactiveSink] of [void] type.
class VoidReactiveSink extends ReactiveSink<void> implements VoidSink {
  /// Creates a [ReactiveSink] of [void] type with its event stream handler.
  ///
  /// See [ReactiveSink] constructor's API documentation for more information.
  //
  // TODO: onVoidEvent should omit a positional parameter like the call method.
  // Example: VoidReactiveSink(() {});
  // Instead of extending, delegating with implementing should make it possible.
  VoidReactiveSink(
    _OnEvent<void> onVoidEvent, {
    _Transform<void> /*nullable*/ transform,
    @required ResourceDisposer /*nullable*/ disposer,
    VoidCallback /*nullable*/ onDispose,
    _OnError /*nullable*/ onError,
    bool /*nullable*/ cancelOnError,
    VoidCallback /*nullable*/ onListen,
    VoidCallback /*nullable*/ onPause,
    VoidCallback /*nullable*/ onResume,
    VoidCallback /*nullable*/ onCancel,
    HandleSubscription<void> /*nullable*/ handleSubscription,
  }) : super(
          onVoidEvent,
          transform: transform,
          disposer: disposer,
          onDispose: onDispose,
          onError: onError,
          cancelOnError: cancelOnError,
          onListen: onListen,
          onPause: onPause,
          onResume: onResume,
          onCancel: onCancel,
          handleSubscription: handleSubscription,
        );

  /// Adds null to the sink.
  ///
  /// Unlike [Sink], added event is ignored after a call to [dispose],
  /// which is the [Sink] version of [ReactiveSink]'s [close].
  @override
  void call([void _]) {
    super.call(null);
  }
}

typedef _OnEvent<E> = void Function(E event);

// TODO: The stackTrace should be optional positional parameter,
// to correspond with Stream's onError signature.
// In current SDK, it is error by Dart analyzer.
// Dart SDK version: 2.10.0-7.0.dev (dev) (Mon Aug 10 22:32:08 2020 +0200) on "macos_x64"
// Revisit with newer SDK.
typedef _OnError = void Function(Object error, StackTrace stackTrace);
typedef _Transform<E> = Stream<E> Function(Stream<E> stream);
typedef HandleSubscription<E> = void Function(
    StreamSubscription<E> subscription);
