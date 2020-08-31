import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:reactive_component/reactive_component.dart';

import 'user.dart';

/// Authentication model.
class Authentication with ReactiveOutputComponent {
  Authentication() {
    _authStateChangesSubscription =
        _firebaseAuth.authStateChanges().listen((user) {
      if (user == null) {
        _user.data = visitor;
      } else if (user.isAnonymous) {
        _user.data = AnonymousUser(user.uid);
      } else {
        // It not about notifying as error output.
        throw UnsupportedError('Unsupported authentication');
      }
    });
  }
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  Reactive<User /*nullable*/ > __user;
  Reactive<User /*nullable*/ > get _user =>
      __user ??= Reactive<User>(null, disposer: disposer);

  Stream<User> get user => _user.stream.where((user) => user != null);

  // Instead of using ReactiveSink, it uses handy familiar function here.
  // But it loses stream transforming ability (throttle, exhaustMap for example)
  // and a "hook" feature (for logging inputs, or do anything) planned
  // in a future version.
  Future<void> signInAnonymously() async {
    await _firebaseAuth.signInAnonymously();
    // will handle authStateChanges on the constructor body.
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // will handle authStateChanges on the constructor body.
  }

  @override
  @protected
  Future<void> doDispose() async {
    await _authStateChangesSubscription?.cancel();
  }

  StreamSubscription<auth.User> /*nullable*/ _authStateChangesSubscription;
}
