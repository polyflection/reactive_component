import 'dart:async';

import 'package:meta/meta.dart';
import 'package:reactive_component/src/reactive_resource.dart';
import 'package:reactive_component/src/resource_disposer.dart';

import 'package:test/test.dart';

void main() {
  group(ReactiveResource, () {
    test('Dispose.', () async {
      final c = _Resource()..dispose();
      await pumpEventQueue();
      await expectLater(c.disposed.first, completion(null));
    });

    group('Delegating a resource disposing', () {
      test('A resource can delegate its disposing to other resource.',
          () async {
        final root = _Resource();
        final sub = _Resource();
        final subSub = _Resource();
        sub.publiclyDelegateDisposingTo(root.publicizedDisposer);
        subSub.publiclyDelegateDisposingTo(sub.publicizedDisposer);

        root.dispose();
        await pumpEventQueue();

        await expectLater(root.disposed.first, completion(null));
        await expectLater(sub.disposed.first, completion(null));
        await expectLater(subSub.disposed.first, completion(null));
      });
    });

    test(
        'When a resource delegate its disposing to another resource, '
        'which has already been disposed, the resource\'s disposing will be started immediately',
        () async {
      final root = _Resource();
      root.dispose();
      root.ownResourceSink.add(1);
      await pumpEventQueue();
      await expectLater(root.disposed.first, completion(null));
      expect(root.isOwnResourceDisposed, isTrue);
      expect(root.isOwnResourceEventHandled, isFalse);

      final sub = _Resource();
      sub.publiclyDelegateDisposingTo(root.publicizedDisposer);
      sub.ownResourceSink.add(1);
      await pumpEventQueue();
      await expectLater(sub.disposed.first, completion(null));
      expect(sub.isOwnResourceDisposed, isTrue);
      expect(sub.isOwnResourceEventHandled, isFalse);
    });
  });
}

class _Resource with ReactiveResource {
  _Resource() {
    _subscription = _ownResource.stream.listen((e) {
      _isEventHandled = true;
    });
  }

  ResourceDisposer get publicizedDisposer => disposer;
  void publiclyDelegateDisposingTo(ResourceDisposer disposer) {
    delegateDisposingTo(disposer);
  }

  Sink<int> get ownResourceSink => _ownResource.sink;
  final _ownResource = StreamController<int>();
  StreamSubscription<int> /*nullable*/ _subscription;

  bool _done = false;
  bool _isEventHandled = false;
  bool get isOwnResourceDisposed => _done;
  bool get isOwnResourceEventHandled => _isEventHandled;

  @override
  void onDispose() {
    _subscription?.onData((_) {});
    _subscription?.onError((_) {});
    super.onDispose();
  }

  @override
  @protected
  Future<void> doDispose() async {
    await _ownResource.close();
    await _ownResource.done.then((_) {
      _done = true;
    });
  }
}
