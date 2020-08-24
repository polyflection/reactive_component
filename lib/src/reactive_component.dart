import 'dart:async';
import 'package:meta/meta.dart';
import 'reactive_resource.dart';
import 'resource_disposer.dart';
import 'sinks.dart';

@streamIO
mixin ReactiveComponent implements ReactiveResource {
  @override
  VoidSink get dispose => disposer.dispose;

  @override
  Stream<void> get disposed => disposer.disposed;

  ResourceDisposer _disposer;
  @override
  @protected
  ResourceDisposer get disposer => _disposer ??=
      ResourceDisposer(doDispose: doDispose, onDispose: onDispose);

  @override
  @protected
  bool get isDisposeEventSent => disposer.isDisposeEventSent;

  /// Dispose this resource.
  ///
  /// A subclass overrides this method for adding additional
  /// resource disposing behavior.
  /// This method is intended to be called by [ResourceDisposer].
  /// A subclass should not call it directly.
  @override
  @protected
  Future<void> doDispose() async {}

  /// A synchronous callback on adding data to [dispose].
  ///
  /// This method is intended to be called by [ResourceDisposer].
  /// A subclass should not call it directly.
  @override
  @protected
  void onDispose() {}

  @override
  @protected
  void delegateDisposingTo(ResourceDisposer disposerDelegate) =>
      disposer.delegateDisposingTo(disposerDelegate);
}

@streamOutput
mixin ReactiveOutputComponent implements ReactiveResource {
  @override
  VoidSink get dispose => disposer.dispose;

  @override
  Stream<void> get disposed => disposer.disposed;

  ResourceDisposer _disposer;
  @override
  @protected
  ResourceDisposer get disposer => _disposer ??=
      ResourceDisposer(doDispose: doDispose, onDispose: onDispose);

  @override
  @protected
  bool get isDisposeEventSent => disposer.isDisposeEventSent;

  /// Dispose this resource.
  ///
  /// A subclass overrides this method for adding additional
  /// resource disposing behavior.
  /// This method is intended to be called by [ResourceDisposer].
  /// A subclass should not call it directly.
  @override
  @protected
  Future<void> doDispose() async {}

  /// A synchronous callback on adding data to [dispose].
  ///
  /// This method is intended to be called by [ResourceDisposer].
  /// A subclass should not call it directly.
  @override
  @protected
  void onDispose() {}

  @override
  @protected
  void delegateDisposingTo(ResourceDisposer disposerDelegate) =>
      disposer.delegateDisposingTo(disposerDelegate);
}

/// All public interface's return type must be Stream or Sink.
///
/// Unimplemented.
const streamIO = _StreamIO();

class _StreamIO {
  const _StreamIO();
}

/// All public interface's return type　must be Stream or void.
///
/// Unimplemented.
const streamOutput = _StreamOutput();

class _StreamOutput {
  const _StreamOutput();
}
