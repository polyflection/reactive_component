import 'dart:async';
import 'package:meta/meta.dart';
import 'resource_disposer.dart';
import 'sinks.dart';

mixin ReactiveResource implements _ReactiveResource {
  @override
  VoidSink get dispose => disposer.dispose;

  @override
  Stream<void> get disposed => disposer.disposed;

  @override
  @protected
  late final ResourceDisposer disposer =
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

abstract class _ReactiveResource {
  VoidSink get dispose;
  Stream<void> get disposed;
  @protected
  ResourceDisposer get disposer;
  @protected
  Future<void> doDispose();
  @protected
  void onDispose() {}
  @protected
  bool get isDisposeEventSent;
  @protected
  void delegateDisposingTo(ResourceDisposer disposerDelegate);
}
