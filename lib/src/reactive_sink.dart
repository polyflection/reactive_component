import 'dart:async';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'reactive_resource.dart';
import 'resource_disposer.dart';
import 'sinks.dart';
import 'typedef.dart';

/// A Sink with its Stream handler.
// TODO: It should be better to split up ReactiveSink into 3 classes.
// ReactiveSink, ReactiveEventSink, ReactiveStreamSink (breaking change).
class ReactiveSink<E> with ReactiveResource implements StreamSink<E> {
  /// ReactiveSink
  ReactiveSink(this._onEvent,
      {_Transform<E>? transform,
      required ResourceDisposer? disposer,
      VoidCallback? onDispose,
      _OnError? onError,
      bool? cancelOnError,
      VoidCallback? onListen,
      VoidCallback? onPause,
      VoidCallback? onResume,
      VoidCallback? onCancel,
      HandleSubscription<E>? handleSubscription})
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
      handleSubscription(eventStreamSubscription!);
    }
  }

  void call(E event) {
    // This avoids "Bad state: Cannot add event after closing" error.
    if (isDisposeEventSent) return;

    _listenOnce();
    _eventStreamController.add(event);
  }

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
  void addError(Object error, [StackTrace? stackTrace]) {
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
  final _Transform<E>? _transform;
  final VoidCallback? _onDispose;
  final _OnError? _onError;
  final bool? _cancelOnError;
  final VoidCallback? _onListen;
  final VoidCallback? _onPause;
  final VoidCallback? _onResume;
  final VoidCallback? _onCancel;

  late final StreamController<E> _eventStreamController = StreamController<E>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel);

  @visibleForTesting
  StreamSubscription<E>? eventStreamSubscription;

  /// Closes [_eventStreamController]'s sink.
  Future<void> _doCloseSink() async {
    if (_eventStreamController.isClosed) return;

    if (_eventStreamController.hasListener) {
      return eventStreamSubscription!.cancel();
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

class VoidReactiveSink extends ReactiveSink<void> implements VoidSink {
  // TODO: onVoidEvent should omit a positional parameter like the call method.
  // Example: VoidReactiveSink(() {});
  // Instead of extending, delegating with implementing should make it possible.
  VoidReactiveSink(
    _OnEvent<void> onVoidEvent, {
    _Transform<void>? transform,
    required ResourceDisposer? disposer,
    VoidCallback? onDispose,
    _OnError? onError,
    bool? cancelOnError,
    VoidCallback? onListen,
    VoidCallback? onPause,
    VoidCallback? onResume,
    VoidCallback? onCancel,
    HandleSubscription<void>? handleSubscription,
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
