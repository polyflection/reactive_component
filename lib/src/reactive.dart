import 'dart:async';

import 'package:meta/meta.dart';
import 'package:reactive_component/reactive_component.dart';

import 'resource_disposer.dart';
import 'typedef.dart';

/// A special stream controller.
class Reactive<D> with ReactiveResource implements StreamController<D> {
  /// Reactive.
  Reactive(
    this._data, {
    required ResourceDisposer? disposer,
    VoidCallback? onDispose,
    VoidCallback? onListen,
    VoidCallback? onPause,
    VoidCallback? onResume,
    FutureOrVoidCallback? onCancel,
  })  : _onDispose = onDispose,
        _onListen = onListen,
        _onPause = onPause,
        _onResume = onResume,
        _onCancel = onCancel {
    if (disposer != null) {
      delegateDisposingTo(disposer);
    }
  }

  @override
  late final Stream<D> stream = Stream<D>.multi(_onListenMultiStream);

  D get data => _data;

  set data(D newData) {
    _data = newData;
    for (final controller in _controllers) {
      controller.add(_data);
    }
  }

  @override
  void add(D newData) {
    data = newData;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    for (final controller in _controllers) {
      controller.addError(error, stackTrace);
    }
  }

  @override
  Future<void> addStream(Stream<D> source, {bool? cancelOnError}) async {
    // need tests carefully.
    await Future.wait(_controllers
        .map((c) => c.addStream(source, cancelOnError: cancelOnError)));
  }

  @override
  Future<void> close() async {
    dispose();
    return disposed.first;
  }

  @override
  bool get isClosed => _controllers.every((c) => c.isClosed);

  @override
  Future<void> get done => _doneCompleter.future;

  /// Returns a view of this object that only exposes the [StreamSink] interface.
  @override
  StreamSink<D> get sink => _StreamSinkWrapper<D>(this);

  @override
  bool get isPaused => _controllers.every((c) => c.isPaused);

  @override
  bool get hasListener => _controllers.any((c) => c.hasListener);

  @override
  VoidCallback? get onListen => _onListen;
  @override
  VoidCallback? get onPause => _onPause;
  @override
  VoidCallback? get onResume => _onResume;
  @override
  FutureOrVoidCallback? get onCancel => _onCancel;

  @override
  set onListen(VoidCallback? onListenHandler) {
    _onListen = onListenHandler;
    // [_onListen] will be called in [_onListenMultiStream],
    // since, unlike other [MultiStreamController] callbacks,
    // [MultiStreamController] has no effect if it sets [onListen] callback.
  }

  @override
  set onPause(VoidCallback? onPauseHandler) {
    _onPause = onPauseHandler;
    for (final controller in _controllers) {
      controller.onPause = _onPause;
    }
  }

  @override
  set onResume(VoidCallback? onResumeHandler) {
    _onResume = onResumeHandler;
    for (final controller in _controllers) {
      controller.onResume = _onResume;
    }
  }

  @override
  set onCancel(FutureOrVoidCallback? onCancelHandler) {
    _onCancel = onCancelHandler;
    for (final controller in _controllers) {
      controller.onCancel =
          () => _handleOnCancelThenRemoveController(_onCancel, controller);
    }
  }

  @override
  @protected
  void onDispose() {
    _onDispose?.call();
  }

  @override
  @protected
  Future<void> doDispose() async {
    await _close();
  }

  D _data;

  final VoidCallback? _onDispose;

  VoidCallback? _onListen;

  /// The callback which is called when a stream is paused.
  /// May be set to `null`, in which case no callback will happen.
  VoidCallback? _onPause;

  /// The callback which is called when a stream is resumed.
  /// May be set to `null`, in which case no callback will happen.
  VoidCallback? _onResume;

  /// The callback which is called when a stream is canceled.
  /// May be set to `null`, in which case no callback will happen.
  FutureOrVoidCallback? _onCancel;

  final _controllers = <MultiStreamController<D>>[];
  final _doneCompleter = Completer<void>();

  Future<void> _onListenMultiStream(MultiStreamController<D> controller) async {
    if (_doneCompleter.isCompleted) {
      await controller.close();
      return;
    }

    controller
      ..onPause = onPause
      ..onResume = onResume
      ..onCancel =
          () => _handleOnCancelThenRemoveController(_onCancel, controller);
    _onListen?.call();
    controller.add(_data);

    _controllers.add(controller);
  }

  Future<void> _handleOnCancelThenRemoveController(
      FutureOrVoidCallback? onCancelHandler,
      MultiStreamController controller) async {
    await Future.sync(() => onCancelHandler?.call());
    _controllers.remove(controller);
  }

  Future<void> _close() async {
    await Future.wait(_controllers.map((c) => c.close()));
    _doneCompleter.complete();
  }
}

typedef FutureOrVoidCallback = FutureOr<void> Function();

/// A class that exposes only the [StreamSink] interface of an object.
class _StreamSinkWrapper<D> implements StreamSink<D> {
  _StreamSinkWrapper(this._target);

  final StreamController<D> _target;

  @override
  void add(D data) {
    _target.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _target.addError(error, stackTrace);
  }

  @override
  Future<void> close() => _target.close();

  @override
  Future<void> addStream(Stream<D> source) => _target.addStream(source);

  @override
  Future<void> get done => _target.done;
}
