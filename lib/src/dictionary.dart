library immutable.src.dictionary;

/// A Mapping from values of [K] to values of [V]
///
/// [Dictionary] is immutable, meaning the associations in a given
/// instance can never change, and persistent, meaning nodes are shared
/// across versions.
abstract class Dictionary<K, V> {
  /// An Iterable of the dictionary keys.
  ///
  /// order is not guaranteed to be consistent.
  Iterable<K> get keys;

  /// An Iterable of the dictionary values.
  ///
  /// order is not guaranteed to be consistent.
  Iterable<V> get values;

  /// The number of keys/values in the dictionary
  int get size;

  /// A private iterable of key-value Tuples
  Iterable<_Tuple2<K, V>> get _pairs;

  const Dictionary._();

  /// Constructs an empty [Dictionary].
  factory Dictionary.empty() => const _EmptyDictionary();

  /// Creates a new [Dictionary] from a [Map].
  factory Dictionary.from(Map<K, V> other) {
    var result = new Dictionary<K, V>.empty();
    other.forEach((K k, V v) {
      result = result.assoc(k, v);
    });
    return result;
  }

  /// Constructs a [Dictionary] from a pair of [Iterable]s
  ///
  /// if their length differs, creation will terminate early.
  factory Dictionary.fromIterables(Iterable<K> keys, Iterable<V> values) {
    var result = new Dictionary<K, V>.empty();
    final keyIter = keys.iterator;
    final valueIter = values.iterator;
    while (keyIter.moveNext() && valueIter.moveNext()) {
      result = result.assoc(keyIter.current, valueIter.current);
    }
    return result;
  }

  /// Returns the value associated with [key], or null
  /// if it's not found.
  V operator [](K key);

  /// Returns a new [Dictionary] with [key] removed.
  ///
  /// If the key is not found, returns the same instance.
  Dictionary<K, V> remove(K key);

  /// Returns true if this contains [key]
  bool containsKey(K key);

  /// Returns a new [Dictionary] with [key] associated to [value]
  ///
  /// if the [Dictionary] already contains [key], the new one will
  /// have the value overwritten.
  Dictionary<K, V> assoc(K key, V value);

  /// Returns a new [Dictionary] with the keys and values from both.
  ///
  /// If key collisions occur, the values from the left Dictionary
  /// are preserved.
  Dictionary<K, V> merge(Dictionary<K, V> other);

  /// Executes a function of [K] and [V] for each pair in [this].
  void forEach(void f(K key, V value));

  @override
  String toString() {
    final StringBuffer buffer = new StringBuffer();
    buffer.write('{');
    var sep = '';
    for (final pair in _pairs) {
      buffer.write('$sep${pair.first}: ${pair.second}');
      sep = ', ';
    }
    buffer.write('}');
    return buffer.toString();
  }
}

/// An internal only class for certain methods.
class _Tuple2<K, V> {
  final K first;
  final V second;
  const _Tuple2(this.first, this.second);
}

class _EmptyDictionary<K, V> extends Dictionary<K, V> {
  static const String _rep = '()';

  const _EmptyDictionary() : super._();

  @override
  Iterable<K> get keys => const [];

  @override
  Iterable<V> get values => const [];

  @override
  int get size => 0;

  @override
  bool containsKey(K _) => false;

  @override
  String toString() => _rep;

  @override
  Dictionary<K, V> remove(K _) => this;

  @override
  V operator [](K _) => null;

  @override
  Dictionary<K, V> merge(Dictionary<K, V> other) => other;

  @override
  Dictionary<K, V> assoc(K key, V value) {
    final root =
        new _BitmapIndexNode<K, V>.empty(0).assoc(0, key.hashCode, key, value);
    return new _NodeDictionary._fromRoot(root, 1);
  }

  @override
  Iterable<_Tuple2<K, V>> get _pairs => const [];

  @override
  void forEach(void f(K key, V value)) {}
}

class _NodeDictionary<K, V> extends Dictionary<K, V> {
  final _Node<K, V> _root;

  @override
  final int size;

  _NodeDictionary._fromRoot(this._root, this.size) : super._();

  @override
  Iterable<K> get keys => _root.keys();

  @override
  Iterable<V> get values => _root.values();

  @override
  bool containsKey(K key) => _root.find(key.hashCode, key) != null;

  @override
  Dictionary<K, V> remove(K key) {
    final newNode = _root.remove(0, key.hashCode, key);
    if (newNode != _root) {
      return new _NodeDictionary._fromRoot(newNode, size - 1);
    }
    return this;
  }

  @override
  V operator [](K key) {
    return _root.find(key.hashCode, key);
  }

  @override
  Dictionary<K, V> merge(Dictionary<K, V> other) => other;

  @override
  Dictionary<K, V> assoc(K key, V value) {
    final newRoot = _root.assoc(0, key.hashCode, key, value);
    return new _NodeDictionary._fromRoot(newRoot, size + 1);
  }

  @override
  Iterable<_Tuple2<K, V>> get _pairs => _root.keysAndValues();

  @override
  void forEach(void f(K key, V value)) {
    for (final tuple in _pairs) {
      f(tuple.first, tuple.second);
    }
  }
}

/// Returns the value of a given offset of 5 bits.
///
/// will always be a value between 0 and 31.
int mask(int hash, int shift) => ((hash & 0xFFFFFFFF) >> shift) & 0x01F;

/// Returns the offset of the bit in the hashcode.
int bitpos(int hash, int shift) => 1 << mask(hash, shift);

/// The population count algorithm returns the number of 1s in a bitstring.
int popcount(int i) {
  i -= ((i >> 1) & 0x55555555);
  i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
  i = ((i + (i >> 4)) & 0x0F0F0F0F);
  i += (i >> 8);
  i += (i >> 16);
  return (i & 0x0000003F);
}

/// [Node] is an interface for building hash tries.
abstract class _Node<K, V> {
  /// retrieves the value associated with the given [key], or null.
  V find(int hash, K key);

  /// associates [key] and [value] with the trie.
  _Node<K, V> assoc(int shift, int hash, K key, V value);

  /// removes [key] from the trie, if present.
  _Node<K, V> remove(int shift, int hash, K key);

  ///
  Iterable<_Tuple2<K, V>> keysAndValues();

  ///
  Iterable<K> keys();

  ///
  Iterable<V> values();
}

/// An [_ArrayNode] is used when there are more than 16 entries in a
/// [_BitmapIndexNode].
///
/// contains up to 32 Nodes, with nulls.
class _ArrayNode<K, V> extends _Node<K, V> {
  final List<_Node<K, V>> _nodes;
  final int _size;
  final int _shift;

  ///
  _ArrayNode(this._nodes, this._shift, this._size);

  /// just need to check the correct index
  ///
  /// returns null via ? operator if value does not exist.
  @override
  V find(int hash, K key) {
    final index = mask(hash, _shift);
    return _nodes[index]?.find(hash, key);
  }

  /// if there is a node at the index, pass assoc down,
  /// otherwise create a new ArrayNode with the slot filled.
  @override
  _Node<K, V> assoc(int shift, int hash, K key, V value) {
    var newSize = _size;
    final index = mask(hash, shift);
    final node = _nodes[index];
    final newNodes = new List<_Node<K, V>>(32);
    for (int i = 0; i < 32; i++) {
      newNodes[i] = _nodes[i];
    }
    if (node != null) {
      newNodes[index] = node.assoc(shift + 5, hash, key, value);
    } else {
      newSize++;
      newNodes[index] = new _LeafNode<K, V>(key, value);
    }
    return new _ArrayNode<K, V>(newNodes, shift, newSize);
  }

  @override
  _Node<K, V> remove(int shift, int hash, K key) {
    final index = mask(hash, shift);
    final node = _nodes[index];
    if (node != null) {
      // TODO: compaction.
      // if the node shrinks below a given size, compact into bitmap.
      final removedNode = node.remove(shift + 5, hash, key);
      final newNodes = new List<_Node<K, V>>.from(_nodes, growable: false);
      newNodes[index] = removedNode;
      return new _ArrayNode(newNodes, _shift, _size - 1);
    } else {
      return this;
    }
  }

  @override
  Iterable<_Tuple2<K, V>> keysAndValues() sync* {
    for (final node in _nodes) {
      yield* node?.keysAndValues();
    }
  }

  @override
  Iterable<K> keys() sync* {
    for (final node in _nodes) {
      yield* node?.keys();
    }
  }

  @override
  Iterable<V> values() sync* {
    for (final node in _nodes) {
      yield* node?.values();
    }
  }
}

/// A [BitmapIndexNode] is used for compact representations
///
/// uses a bitmap to compact the list of nodes.
class _BitmapIndexNode<K, V> extends _Node<K, V> {
  final List<_Node<K, V>> _nodes;
  final int _shift;
  final int _bitmap;

  ///
  _BitmapIndexNode(this._nodes, this._shift, this._bitmap);

  ///
  _BitmapIndexNode.empty(this._shift)
      : _nodes = const [],
        _bitmap = 0;

  int _index(int bit) => popcount(_bitmap & (bit - 1));

  @override
  V find(int hash, K key) {
    final bit = bitpos(hash, _shift);
    if ((_bitmap & bit) != 0) {
      return _nodes[_index(bit)].find(hash, key);
    }
    return null;
  }

  @override
  _Node<K, V> remove(int shift, int hash, K key) {
    final bit = bitpos(hash, _shift);
    if ((_bitmap & bit) != 0) {
      // TODO: compaction to null if empty.
      final newNodes = new List<_Node<K, V>>.from(_nodes)
        ..removeAt(_index(bit));
      return new _BitmapIndexNode(newNodes, _shift, _bitmap ^ bit);
    } else {
      return this;
    }
  }

  @override
  _Node<K, V> assoc(int shift, int hash, K key, V value) {
    int bit = bitpos(hash, shift);
    int index = _index(bit);
    if ((_bitmap & bit) != 0) {
      final newNodes = new List<_Node<K, V>>.from(_nodes, growable: false);
      newNodes[index] = _nodes[index].assoc(shift + 5, hash, key, value);
      return new _BitmapIndexNode(newNodes, shift, _bitmap);
    } else {
      int n = popcount(_bitmap);
      if (n >= 16) {
        // convert to [ArrayNode]
        final newNodes =
            new List<_Node<K, V>>.filled(32, null, growable: false);
        newNodes[mask(hash, shift)] = new _LeafNode<K, V>(key, value);
        int j = 0;
        for (int i = 0; i < 32; i++) {
          if (((_bitmap >> i) & 1) != 0) {
            newNodes[i] = _nodes[j];
            j++;
          }
        }
        return new _ArrayNode<K, V>(newNodes, shift, n);
      } else {
        final newNodes = new List<_Node<K, V>>();
        for (int i = 0; i < n; i++) {
          newNodes.add(_nodes[i]);
        }
        newNodes.insert(index, new _LeafNode<K, V>(key, value));
        return new _BitmapIndexNode<K, V>(newNodes, shift, _bitmap | bit);
      }
    }
  }

  @override
  Iterable<_Tuple2<K, V>> keysAndValues() sync* {
    for (final node in _nodes) {
      yield* node.keysAndValues();
    }
  }

  @override
  Iterable<K> keys() sync* {
    for (final node in _nodes) {
      yield* node.keys();
    }
  }

  @override
  Iterable<V> values() sync* {
    for (final node in _nodes) {
      yield* node.values();
    }
  }
}

/// A [LeafNode] just contains a value.
/// TODO: remove problematic field name `hashcode`.
class _LeafNode<K, V> extends _Node<K, V> {
  final K _key;
  final V _value;
  final int _hashcode;

  ///
  _LeafNode(K key, this._value)
      : _hashcode = key.hashCode,
        _key = key;

  /// Once we have reached a [LeafNode], find just returns the values
  @override
  V find(int hash, K key) => _value;

  /// assoc on a [LeafNode] might mean a collision.
  @override
  _Node<K, V> assoc(int shift, int hash, K key, V value) {
    if (_hashcode == hash || shift > 32) {
      return new _CollisionNode([_key, key], [_value, value], hash);
    }
    return new _BitmapIndexNode<K, V>.empty(shift)
        .assoc(shift, _hashcode, _key, _value)
        .assoc(shift, hash, key, value);
  }

  @override
  _Node<K, V> remove(int shift, int hash, K key) {
    if (key == _key) {
      return null;
    }
    return this;
  }

  @override
  Iterable<_Tuple2<K, V>> keysAndValues() sync* {
    yield new _Tuple2(_key, _value);
  }

  @override
  Iterable<K> keys() sync* {
    yield _key;
  }

  @override
  Iterable<V> values() sync* {
    yield _value;
  }
}

/// A [CollisionNode] contains multiple values with the same hashcode
class _CollisionNode<K, V> extends _Node<K, V> {
  final int _hashcode;
  final List<K> _keys;
  final List<V> _values;

  ///
  _CollisionNode(this._keys, this._values, this._hashcode);

  /// Since all keys have the same hash, we have to inspect them with
  /// equality.
  @override
  V find(int hash, K key) {
    if (hash != _hashcode) {
      return null;
    }
    for (int i = 0; i < _keys.length; i++) {
      if (key == _keys[i]) {
        return _values[i];
      }
    }
    return null;
  }

  /// Assoc to a CollisionNode means that there is another collision,
  /// or that we need to deepen the tree.
  @override
  _Node<K, V> assoc(int shift, int hash, K key, V value) {
    if (hash != _hashcode) {
      return new _BitmapIndexNode<K, V>(
              [this], shift, (0 | bitpos(_hashcode, shift)))
          .assoc(shift, hash, key, value);
    }
    final n = _keys.length;
    final newKeys = new List<K>(n + 1);
    final newValues = new List<V>(n + 1);
    for (int i = 0; i < n; i++) {
      newKeys[i] = _keys[i];
      newValues[i] = _values[i];
    }
    newKeys[n] = key;
    newValues[n] = value;
    return new _CollisionNode(newKeys, newValues, _hashcode);
  }

  /// must check identity to remove key, if there is a single value left,
  /// promote to a [_LeafNode].
  @override
  _Node<K, V> remove(int shift, int hash, K key) {
    final n = _keys.length;
    final newKeys = new List<K>();
    final newValues = new List<V>();
    for (int i = 0; i < n; i++) {
      if (_keys[i] != key) {
        newKeys.add(_keys[i]);
        newValues.add(_values[i]);
      }
    }
    if (newKeys.length == 1) {
      return new _LeafNode<K, V>(newKeys[0], newValues[0]);
    } else {
      return new _CollisionNode<K, V>(newKeys, newValues, _hashcode);
    }
  }

  @override
  Iterable<_Tuple2<K, V>> keysAndValues() sync* {
    for (int i = 0; i < _keys.length; i++) {
      yield new _Tuple2(_keys[i], _values[i]);
    }
  }

  @override
  Iterable<K> keys() sync* {
    yield* _keys;
  }

  @override
  Iterable<V> values() sync* {
    yield* _values;
  }
}
