import 'package:test/test.dart';

import '../lib/src/dictionary.dart';

void main() {


  group('Dictionary', () {

    test('creates an empty dictionary', () {
      final empty = new Dictionary.empty();
      expect(empty.values, isEmpty);
      expect(empty.keys, isEmpty);
    });

    test('creates a dictionary of one value', () {
      final empty = new Dictionary<int,int>.empty();
      final populated = empty.assoc(1, 2);
      expect(populated.containsKey(1), isTrue);
      expect(populated[1], equals(2));
    });

    test('creates a dictionary of many values', () {
      var modified  = new Dictionary<String, int>.empty();
      modified = modified.assoc("one", 1);
      modified = modified.assoc("two", 2);
      modified = modified.assoc("three", 3);
      modified = modified.assoc("four", 4);
      expect(modified["one"], equals(1));
      expect(modified["two"], equals(2));
      expect(modified["three"], equals(3));
      expect(modified["four"], equals(4));
    });

    test('allows keys to be removed', () {
      var modified = new Dictionary<String, int>.empty();
      modified = modified.assoc("one", 2);
      modified = modified.assoc("three", 3);
      modified = modified.remove("one");
      expect(modified["three"], equals(3));
      expect(modified["one"], isNull);
    });
  });
}
