/// A Sink with [call] method for shorthand notation.
abstract class VoidSink extends Sink<void> {
  /// Adds null to the sink.
  void call() {
    add(null);
  }
}
