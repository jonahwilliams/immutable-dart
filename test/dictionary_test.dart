import 'package:test/test.dart';

import 'package:immutable/src/dictionary.dart';

void main() {
  group('Dictionary', () {
    test('can be created with zero values', () {
      final empty = new Dictionary.empty();
      expect(empty.values, isEmpty);
      expect(empty.keys, isEmpty);
    });

    test('is stable for one value', () {
      final empty = new Dictionary<int, int>.empty();
      final populated = empty.assoc(1, 2);
      expect(populated.containsKey(1), isTrue);
      expect(populated[1], equals(2));
    });

    test('is stable for less than 16 values', () {
      var modified = new Dictionary<String, int>.empty();
      modified = modified.assoc("one", 1);
      modified = modified.assoc("two", 2);
      modified = modified.assoc("three", 3);
      modified = modified.assoc("four", 4);
      expect(modified["one"], equals(1));
      expect(modified["two"], equals(2));
      expect(modified["three"], equals(3));
      expect(modified["four"], equals(4));
    });

    test('is stable for 100,000 values', () {
      final source = new List.generate(100000, (i) => '$i');
      var modified = new Dictionary<String, int>.empty();
      for (String item in source) {
        modified = modified.assoc(item, int.parse(item));
      }
      expect(modified.size, equals(100000));
      for (String item in source) {
        expect(modified[item], equals(int.parse(item)));
      }
    });

    test('allows keys to be removed', () {
      var modified = new Dictionary<String, int>.empty();
      modified = modified.assoc("one", 2);
      modified = modified.assoc("three", 3);
      modified = modified.remove("one");
      expect(modified["three"], equals(3));
      expect(modified["one"], isNull);
    });

    test('correctly handles collisions', () {
      var modified = new Dictionary<_DebugNode, int>.empty();
      final key1 = new _DebugNode(1);
      final key2 = new _DebugNode(2);
      final key3 = new _DebugNode(3);

      modified = modified.assoc(key1, 1);
      modified = modified.assoc(key2, 2);
      modified = modified.assoc(key3, 3);

      expect(modified[key1], 1);
      expect(modified[key2], 2);
      expect(modified[key3], 3);
    });

    test('prints correctly', () {
      final dict = new Dictionary.fromIterables([1, 2, 3], [1, 2, 3]);
      expect(dict.toString(), '{1: 1, 2: 2, 3: 3}');
    });
  });
}

class _DebugNode {
  @override
  final int hashCode;
  _DebugNode(this.hashCode);
}
