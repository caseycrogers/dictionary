extension MapUtils<K, V> on Map<K, V> {
  V getOrElse(K key, V defaultValue) {
    if (containsKey(key)) {
      return this[key]!;
    } else {
      this[key] = defaultValue;
      return defaultValue;
    }
  }

  Iterable<T> mapDown<T>(T Function(K key, V value) f) {
    return entries.map((e) => f(e.key, e.value));
  }
}

extension NotShittyList<T> on List<T> {
  T get(int index, {required T orElse}) =>
      index < length ? this[index] : orElse;

  List<T>? get emptyToNull => isEmpty ? null : this;
}
