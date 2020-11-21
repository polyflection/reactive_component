// @dart=2.9
import 'dart:async';

import 'package:composing_firebase/anonymous_messages/messages_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:reactive_component/reactive_component.dart';

import 'message.dart';

class AnonymousMessages with ReactiveComponent {
  AnonymousMessages(this._repository) {
    _subscription = _repository.messages.listen((messages) {
      _messages.data = _messages.data..addAll(messages);
    });
  }

  Stream<List<Message>> get messages => _messages.stream;

  final MessagesRepository _repository;
  StreamSubscription<List<Message>> /*nullable*/ _subscription;

  Reactive<List<Message>> __messages;
  Reactive<List<Message>> get _messages =>
      __messages ??= Reactive<List<Message>>([], disposer: disposer);

  @override
  @protected
  Future<void> doDispose() async {
    await _subscription.cancel();
  }
}
