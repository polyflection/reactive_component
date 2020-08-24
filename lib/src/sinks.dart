abstract class VoidSink extends Sink<void> {
  void call() {
    add(null);
  }
}
