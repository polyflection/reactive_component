import 'dart:async';
import 'package:composing_firebase/anonymous_messages/messages_repository.dart';
import 'package:composing_firebase/authentication/user.dart';
import 'package:rxdart/rxdart.dart';
import 'package:reactive_component/reactive_component.dart';

/// MessageComposer for AnonymousMessages.
///
/// This component depends on an AnonymousUser.
/// When a user signs out to become a visitor, a client must handle
/// this component to be disposed.
///
/// This could have a user stream dependency on the constructor
/// or a sink input, so that a client wouldn't have to take care of
/// current user's kind, but in that case, more complex test cases
/// were to be required on this component;
/// - when any user has not been delivered
/// - when a visitor is delivered
/// - when an AnonymousUser is delivered
///
/// Also, unlike typical Flutter form that is provided by the framework,
/// this component has its own form model and the validation for its
/// state consistency. It send and receive the form state updates with a Widget.
/// If it relies on an existing Flutter form state outside would be easier
/// approach, while it means they are tightly coupled.
///
/// It is a matter of design choice on which way to adopt, depending
/// on a situation.
class MessageComposer with ReactiveComponent {
  MessageComposer(this._repository, this._user)
      : assert(_repository != null),
        assert(_user != null);
  final AnonymousUser _user;
  final MessagesAddingRepository _repository;

  ReactiveSink<String> _updateMessageText;
  ReactiveSink<String> get updateMessageText =>
      _updateMessageText ??
      ReactiveSink<String>((message) {
        final data = _form.data;
        _form.data
          .._message = message
          .._validate();
        _form.data = data;
      }, disposer: disposer);

  VoidReactiveSink _send;
  VoidReactiveSink get send =>
      _send ??= VoidReactiveSink((_) {}, transform: (stream) {
        return stream.exhaustMap((_) async* {
          _sendPhase.data = _SendPhaseData.doing();

          _form.data._validate();
          if (!_form.data.isValid) {
            _sendPhase.data = _SendPhaseData.failure();
            _sendPhase.data = _SendPhaseData.ready();
            return;
          }

          try {
            await _repository.add(_form.data.message, _user);
            _sendPhase.data = _SendPhaseData.success();
          } catch (error, stackTrace) {
            // There is a chance to send the error to a server here.
            _sendPhase.data = _SendPhaseData.failure(error, stackTrace);
          } finally {
            // Or, delayed?

            _form.data = _form.data.._clear();
            _sendPhase.data = _SendPhaseData.ready();
          }
        });
      }, disposer: disposer);

  Reactive<MessageForm> __form;
  Reactive<MessageForm> get _form =>
      __form ??= Reactive<MessageForm>(MessageForm(), disposer: disposer);
  Stream<MessageForm> get form => _form.stream;

  Reactive<_SendPhaseData> __sendPhase;
  Reactive<_SendPhaseData> get _sendPhase => __sendPhase ??=
      Reactive<_SendPhaseData>(_SendPhaseData.ready(), disposer: disposer);

  Stream<bool> get canSend => CombineLatestStream.combine2(
      _sendPhase.stream,
      _form.stream,
      (phase, form) => phase.phase == _SendPhaseKind.ready && form.isValid);

  Stream<void> get sent => _sendPhase.stream
      .where((e) => e.phase == _SendPhaseKind.success)
      .mapTo(null);

  Stream<String> get errorMessage => _sendPhase.stream
      .where((e) => e.phase == _SendPhaseKind.failure)
      .map((_) => 'Something went wrong with sending.');
}

/// Message form model.
///
/// Only the getters are publicized.
/// The setters and commands will never be publicized.
class MessageForm {
  String _message = '';
  String get message => _message;
  bool _isValid = false;
  bool get isValid => _isValid;
  void _validate() => _isValid = message.isNotEmpty;
  void _clear() => _message = '';
}

class _SendPhaseData {
  _SendPhaseData.ready() : this._(_SendPhaseKind.ready);
  _SendPhaseData.doing() : this._(_SendPhaseKind.doing);
  _SendPhaseData.success() : this._(_SendPhaseKind.success);
  _SendPhaseData.failure([Object error, StackTrace stackTrace])
      : this._(_SendPhaseKind.failure, error: error, stackTrace: stackTrace);

  _SendPhaseData._(this.phase, {this.error, this.stackTrace});

  final _SendPhaseKind phase;
  final Object /*nullable*/ error;
  final Object /*nullable*/ stackTrace;
}

enum _SendPhaseKind {
  ready,
  doing,
  success,
  failure,
}
