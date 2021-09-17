import 'package:flutter/cupertino.dart';

extension ValueNotifierExtension<T> on ValueNotifier<T> {
  ValueNotifier<R> map<R>(R Function(T value) mapper) {
    final ValueNotifier<R> proxyNotifier = ValueNotifier(mapper(value));
    void onValueChanged() {
      proxyNotifier.value = mapper(value);
    }

    addListener(onValueChanged);
    return proxyNotifier;
  }

  ValueNotifier<R> expand<R>(ValueNotifier<R> Function(T value) mapper) {
    ValueNotifier<R>? notifier;
    late final ValueNotifier<R> proxyNotifier = ValueNotifier(notifier!.value);

    void onInnerValueChanged() {
      proxyNotifier.value = notifier!.value;
    }
    void onValueChanged() {
      notifier?.removeListener(onInnerValueChanged);
      notifier = mapper(value);
      notifier!.addListener(onInnerValueChanged);
    }

    // Call once to initialize.
    onValueChanged();
    addListener(onValueChanged);
    return proxyNotifier;
  }
}
