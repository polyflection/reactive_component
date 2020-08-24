import 'dart:async';

import 'package:meta/meta.dart';

import 'sinks.dart';
import 'typedef.dart';

class ResourceDisposer {
  ResourceDisposer(
      {@required Future<void> Function() /*nullable*/ doDispose,
      @required VoidCallback /*nullable*/ onDispose})
      : _doDispose = doDispose,
        _onDispose = onDispose;

  VoidSink get dispose {
    return _VoidSink(_disposeController.sink, () => !_isDisposeEventSent,
        _wrapOnDispose(_onDispose));
  }

  Stream<void> get disposed => Stream.fromFuture(_disposeController.done);

  bool get isDisposeEventSent => _isDisposeEventSent;

  void register(ResourceDisposer disposer) {
    if (isDisposeEventSent) {
      disposer.dispose();
    } else {
      _disposers.add(disposer);
    }
  }

  void delegateDisposingTo(ResourceDisposer disposerDelegate) {
    disposerDelegate.register(this);
  }

  final Future<void> Function() /*nullable*/ _doDispose;
  final List<ResourceDisposer> _disposers = [];

  StreamController<void> __disposeController;
  StreamController<void> get _disposeController => __disposeController ??=
      StreamController<void>()..stream.listen((_) => _dispose());

  Future<void> _dispose() => _doDispose != null
      ? Future.wait([_doDispose(), _disposePrivateResource()])
      : _disposePrivateResource();

  Future<void> _disposePrivateResource() => _disposeController.close();

  final VoidCallback /*nullable*/ _onDispose;

  VoidCallback _wrapOnDispose(VoidCallback /*nullable*/ onDispose) {
    return () {
      if (_isDisposeEventSent) return;
      _isDisposeEventSent = true;
      for (final disposer in _disposers) {
        disposer.dispose();
      }
      onDispose?.call();
    };
  }

  bool _isDisposeEventSent = false;
}

class _VoidSink implements VoidSink {
  _VoidSink(this._sink, this._canAdd, this._onAdd);

  final Sink _sink;
  final bool Function() _canAdd;
  final VoidCallback _onAdd;

  @override
  void call() {
    if (_canAdd()) {
      _sink.add(null);
      _onAdd();
    }
  }

  @override
  void add(void _) {
    call();
  }

  @override
  void close() {
    call();
  }
}
