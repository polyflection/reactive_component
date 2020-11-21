# 0.3.0-nullsafety.0

- Null safety version.

# 0.2.0

- Breaking change: divide ReactiveSink into three classes.

ReactiveSink is divided into ReactiveSink, ReactiveEventSink, and ReactiveStreamSink.
Also, VoidReactiveSink is divided into VoidReactiveSink, VoidReactiveEventSink, and VoidReactiveStreamSink. 

Each VoidReactiveSink, VoidReactiveEventSink, and VoidReactiveStreamSink takes a first positional
 parameter as `void Function()` instead of `void Function(void data)`.

# 0.1.2+3

- Improve documentations.

# 0.1.2+2

- Improve README.

# 0.1.2+1

- Improve README and other documentations.

# 0.1.2

- Add public API documentations.
- Add two examples: flutter_counter, and composing_firebase.

# 0.1.1

- Fix SDK constraint.

# 0.1.0

- First non null safety version.

# 0.1.0-nullsafety-dev.1

- Initial pre-release version.

# 0.1.0-nullsafety

- Initial version.
