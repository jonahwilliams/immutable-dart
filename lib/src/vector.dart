import 'package:meta/meta.dart';

/// The Mask `31`
const int _mask = (1 << 5) - 1;

/// 32
const int _trieSize = 32;

/// [Vector] is a persistent bit-partitioned Vector trie based on Clojure
/// and Scala implementations.
abstract class Vector<T> implements Iterable<T> {
  const Vector._();

  /// Creates a new Vector from any interable.
  ///
  /// example:
  ///   final xs = new Vector.fromIterable([1, 2, 3, 4]);
  ///   print(xs);
  ///   => [1, 2, 3, 4]
  factory Vector.fromIterable(Iterable<T> xs) {
    if (xs.isEmpty) {
      return new _ImmutableVector.empty();
    }

    final length = xs.length;
    // calculate the necessary depth of the tree by bit shifting by 2^5.
    int shift = length;
    int depth = 0;
    while (shift > 0) {
      depth++;
      shift = shift >> 5;
    }

    final root = fromDepth/*<T>*/(depth);
    var index = 0;
    for (final x in xs) {
      root.set(index, 5 * (depth - 1), x);
      index++;
    }
    return new _ImmutableVector.fromRoot(length, depth, root);
  }

  /// Creates an empty Vector.
  factory Vector.empty() => new _ImmutableVector.empty();

  @override
  T get first => this[0];

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterator<T> get iterator => new _VectorIterator(this);

  @override
  T get last {
    if (isEmpty) {
      throw new StateError('Vector is empty and has no last value.');
    }
    return this[length - 1];
  }

  @override
  int get length;

  @override
  T get single {
    if (length == 1) {
      return this[0];
    }
    throw new StateError('Vector has length $length');
  }

  /// Forwards to an iterable of the underlying values.
  @protected
  Iterable<T> get _values;

  /// Index operator works the same as a normal list.
  ///
  /// Throws a state error if the index is out of bounds.
  T operator [](int index);

  /// Returns a Vector without the last item
  ///
  /// Throws a state error if it is empty.
  Vector<T> removeLast();

  /// Creates a new Vector with [value] append to the end.
  Vector<T> append(T value);

  /// Creates a new Vector with the _values from [other] concatenated 
  /// on the end.
  Vector<T> concat(Iterable<T> other);

  @override
  bool any(Predicate<T> test) => _values.any(test);

  @override
  bool contains(Object value) => _values.contains(value);

  @override
  T elementAt(int index) => this[index];

  @override
  bool every(Predicate<T> test) => _values.every(test);

  @override
  Iterable<S> expand/*<S>*/(Iterable<S> f(T value)) => _values.expand(f);

  @override
  T firstWhere(Predicate<T> test, {Lazy<T> orElse}) =>
      _values.firstWhere(test, orElse: orElse);

  @override
  S fold/*<S>*/(S init, S reducer(S acc, T value)) =>
      _values.fold/*<S>*/(init, reducer);

  @override
  void forEach(void f(T value)) => _values.forEach(f);

  @override
  String join([String sep]) => _values.join(sep);

  @override
  T lastWhere(Predicate<T> test, {Lazy<T> orElse}) =>
      _values.lastWhere(test, orElse: orElse);

  @override
  Iterable<S> map/*<S>*/(S f(T value)) => _values.map(f);

  @override
  T reduce(T f(T a, T b)) => _values.reduce(f);

  @override
  T singleWhere(Predicate<T> test) => _values.singleWhere(test);

  @override
  Iterable<T> skip(int n) => _values.skip(n);

  @override
  Iterable<T> skipWhile(Predicate<T> test) => _values.skipWhile(test);

  @override
  Iterable<T> take(int n) => _values.take(n);

  @override
  Iterable<T> takeWhile(Predicate<T> test) => _values.takeWhile(test);

  @override
  List<T> toList({bool growable: false}) =>
      new List.from(_values, growable: growable);

  @override
  Set<T> toSet() => new Set.from(_values);

  @override
  String toString() => '[' + join(', ') + ']';

  /// Creates a new Vector with the value in the given [index] replaced by
  /// [value].
  Vector<T> update(int index, T value);

  @override
  Iterable<T> where(Predicate<T> test) => _values.where(test);
}

class _ImmutableVector<T> extends Vector<T> {
  @override
  final int length;

  /// Maximum depth of the tree.
  @protected
  final int depth;

  Node<T> _root;

  /// Creates a new empty Vector.
  ///
  /// example:
  ///   final xs = new Vector.empty();
  ///   print(xs);
  ///   => []
  _ImmutableVector.empty()
      : length = 0,
        depth = 1,
        _root = new Leaf.empty(),
        super._();

  /// Private constructor for building new Vectors from path copied roots.
  _ImmutableVector.fromRoot(this.length, this.depth, this._root) : super._();

  @override
  @protected
  Iterable<T> get _values => _root.traverse();

  @override
  T operator [](int index) {
    assert(index > 0);
    if (index >= length) {
      throw new StateError(
          'Index out of bounds: $index is greater than $length');
    }
    return _root.get(index, 5 * (depth - 1));
  }

  @override
  Vector<T> append(T value) {
    if (length >= _trieSize << (5 * (depth - 1))) {
      final xs = new List<Node<T>>(32);
      final shift = 5 * (depth - 1);
      xs[0] = _root;
      xs[1] = (shift > 0)
          ? new Branch<T>.empty().copy(length, shift, value)
          : new Leaf<T>.empty().copy(length, shift, value);
      final newRoot = new Branch.fromList(xs);
      return new _ImmutableVector<T>.fromRoot(length + 1, depth + 1, newRoot);
    }
    final newRoot = _root.copy(length, 5 * (depth - 1), value);
    return new _ImmutableVector<T>.fromRoot(length + 1, depth, newRoot);
  }

  @override
  Vector<T> concat(Iterable<T> other) {
    Iterable<T> combine(Iterable<T> xs, Iterable<T> ys) sync* {
      yield* xs;
      yield* ys;
    }

    return new Vector.fromIterable(combine(_values, other));
  }

  @override
  Vector<T> removeLast() {
    // TODO: shrink Vector.
    final newRoot = _root.copy(length - 1, 5 * (depth - 1), null);
    return new _ImmutableVector.fromRoot(length - 1, depth, newRoot);
  }

  @override
  Vector<T> update(int index, T value) {
    if (index >= length) {
      throw new StateError(
          'index $index is out of bounds for Vector of length $length');
    }
    final newRoot = _root.copy(index, 5 * (depth - 1), value);
    return new _ImmutableVector.fromRoot(length, depth, newRoot);
  }
}

class _VectorIterator<T> implements Iterator<T> {
  T _current;
  int _position;
  int _length;
  Vector<T> _vec;

  _VectorIterator(Vector<T> vec) {
    _position = -1;
    _length = vec.length;
    _vec = vec;
  }

  @override
  T get current => _current;

  @override
  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _vec[nextPosition];
      _position = nextPosition;
      return true;
    }
    _current = null;
    _position = _length;
    return false;
  }
}

/// [Node] represents the internal interface of a Trie.
///
/// There are two concrete implementations:
///
///   [Leaf] represents a node of values of type T
///   [Branch] represents a node of references to other [Node]
///
/// While the overall structure is immutable, Nodes can be freely mutated
/// by the Vector implentation for efficiency.
abstract class Node<T> {
  /// Produces a new path with the given index and shift.
  Node<T> copy(int index, int shift, T value);

  /// Retrieves the value at the [index].
  ///
  /// with a depth of two, when we grab an index we need to calculate
  /// 5 bits at a time.  [shift] tells you how far to shift to grab the right
  /// bits.
  ///
  /// for a tree of depth two:
  ///   shift = 5 * (2 - 1)
  /// ‎  shift = 5
  ///   0b1000000000 >> 5
  ///   0b1000 & 11110
  ///   0b1000
  ///   index is 8.
  T get(int index, int shift);

  /// mutates the provided index.
  void set(int index, int shift, T value);

  /// traverses the tree.
  Iterable<T> traverse();
}

///
class Branch<T> extends Node<T> {
  final List<Node<T>> values;

  Branch.empty() : values = new List(_trieSize);
  Branch.fromList(this.values);

  Node<T> copy(int index, int shift, T value) {
    List<Node<T>> results = new List(_trieSize);
    final key = ((index & 0xFFFFFFFF) >> shift) & _mask;
    for (int i = 0; i < _trieSize; i++) {
      if (i == key) {
        final res = values[i];
        if (res == null) {
          results[i] = (shift > 5)
              ? new Branch<T>.empty().copy(index, shift - 5, value)
              : new Leaf<T>.empty().copy(index, shift, value);
        } else {
          results[i] = res.copy(index, shift - 5, value);
        }
      } else {
        results[i] = values[i];
      }
    }
    return new Branch.fromList(results);
  }

  T get(int index, int shift) {
    return values[((index & 0xFFFFFFFF) >> shift) & _mask]
        .get(index, shift - 5);
  }

  void set(int index, int shift, T value) {
    values[((index & 0xFFFFFFFF) >> shift) & _mask]
        .set(index, shift - 5, value);
  }

  Iterable<T> traverse() sync* {
    for (int i = 0; i < _trieSize; i++) {
      final value = values[i];
      if (value == null) {
        return;
      }
      yield* value.traverse();
    }
  }
}

///
class Leaf<T> extends Node<T> {
  /// The values contained in the leaf.
  final List<T> values;

  Leaf.empty() : values = new List(_trieSize);
  Leaf.fromList(this.values);

  Node<T> copy(int index, int _, T value) {
    List<T> results = new List(_trieSize);
    final key = index & _mask;
    for (int i = 0; i < _trieSize; i++) {
      if (key == i) {
        results[i] = value;
      } else {
        results[i] = values[i];
      }
    }
    return new Leaf.fromList(results);
  }

  T get(int index, int _) {
    return values[index & _mask];
  }

  void set(int index, int _, T value) {
    values[index & _mask] = value;
  }

  Iterable<T> traverse() sync* {
    for (int i = 0; i < _trieSize; i++) {
      final value = values[i];
      if (value == null) {
        return;
      }
      yield value;
    }
  }
}

/// helper functions which recursively builds a tree for a fixed depth.
///
/// example:
///   final node = _fromDepth(2);
///   => Branch(Leaf(),Leaf(),...)
Node<T> fromDepth/*<T>*/(int depth) {
  if (depth == 1) {
    return new Leaf.empty();
  }
  List<Node<T>> values = new List(_trieSize);
  for (int i = 0; i < _trieSize; i++) {
    values[i] = fromDepth/*<T>*/(depth - 1);
  }
  return new Branch.fromList(values);
}

///
typedef T Lazy<T>();

///
typedef bool Predicate<T>(T item);
