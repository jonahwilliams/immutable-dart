import 'package:test/test.dart';

import 'package:immutable/immutable.dart';

void main() {
  group('Vector', () {
    group('construction', () {
      test(' Vector.empty', () {
        expect(new Vector.empty(), orderedEquals([]));
      });
      test('Vector.fromIterable', () {
        expect(
            new Vector.fromIterable([1, 2, 3, 4]), orderedEquals([1, 2, 3, 4]));
      });

      test('Vector.fromIterable on empty Iterable', () {
        expect(new Vector.fromIterable([]), orderedEquals([]));
      });
    });

    group('method', () {
      group('append', () {
        // length: 0
        Vector<int> empty;
        // length: 31
        Vector<int> short;
        List<int> shortSrc;
        // length: 1031
        Vector<int> medium;
        List<int> mediumSrc;
        // length: 32767
        Vector<int> long;
        List<int> longSrc;

        setUp(() {
          empty = new Vector.empty();
          shortSrc = new List.generate(31, (i) => i);
          mediumSrc = new List.generate(1023, (i) => i);
          longSrc = new List.generate(32767, (i) => i);
          short = new Vector.fromIterable(shortSrc);
          medium = new Vector.fromIterable(mediumSrc);
          long = new Vector.fromIterable(longSrc);
        });

        test('increases length by 1', () {
          final vecEmpty = empty.append(-1);
          final vecShort = short.append(-1);
          final vecMedium = medium.append(-1);
          final vecLong = long.append(-1);

          expect(vecEmpty.length, equals(1));
          expect(vecShort.length, equals(32));
          expect(vecMedium.length, equals(1024));
          expect(vecLong.length, equals(32768));
        });

        test('sets last element to 1', () {
          final vecEmpty = empty.append(1);
          final vecShort = short.append(1);
          final vecMedium = medium.append(1);
          final vecLong = long.append(1);

          expect(vecEmpty[0], equals(1));
          expect(vecShort[31], equals(1));
          expect(vecMedium[1023], equals(1));
          expect(vecLong[32767], equals(1));
        });

        test('does not change original Vector', () {
          empty.append(-1);
          short.append(-1);
          medium.append(-1);
          long.append(-1);

          expect(empty, orderedEquals([]));
          expect(short, orderedEquals(shortSrc));
          expect(medium, orderedEquals(mediumSrc));
          expect(long, orderedEquals(longSrc));
        });
      });

      group('update', () {
        // length: 0
        Vector<int> empty;
        // length: 31
        Vector<int> short;
        List<int> shortSrc;
        // length: 1031
        Vector<int> medium;
        List<int> mediumSrc;
        // length: 32767
        Vector<int> long;
        List<int> longSrc;

        setUp(() {
          empty = new Vector.empty();
          shortSrc = new List.generate(31, (i) => i);
          mediumSrc = new List.generate(1031, (i) => i);
          longSrc = new List.generate(32767, (i) => i);
          short = new Vector.fromIterable(shortSrc);
          medium = new Vector.fromIterable(mediumSrc);
          long = new Vector.fromIterable(longSrc);
        });
        test('throws when out of bounds', () {
          expect(() => empty.update(0, -1), throwsStateError);
          expect(() => short.update(32, -1), throwsStateError);
          expect(() => medium.update(1033, -1), throwsStateError);
          expect(() => long.update(32768, -1), throwsStateError);
        });

        test('changes correct indexes', () {
          expect(short.update(2, -1)[2], equals(-1));
          expect(medium.update(899, -1)[899], equals(-1));
          expect(long.update(15000, -1)[15000], equals(-1));
        });

        test('leaves original unchanged', () {
          expect(short..update(2, -1), orderedEquals(shortSrc));
          expect(medium..update(899, -1), orderedEquals(mediumSrc));
          expect(long..update(15000, -1), orderedEquals(longSrc));
        });
      });

      test('[] operator', () {
        final list = new List.generate(31, (i) => i);
        final vec = new Vector.fromIterable(list);
        expect(vec[30], 30);
        expect(vec[0], 0);
        expect(vec[15], 15);
      });

      test('concat', () {
        final list = new List.generate(31, (i) => i);
        final vec = new Vector.fromIterable(list);
        final vec2 = vec.concat([1, 2, 3, 4, 5]);
        expect(vec, orderedEquals(list));
        expect(vec2, orderedEquals(list..addAll([1, 2, 3, 4, 5])));
      });

      test('remove', () {
        final list = new List.generate(10, (i) => i);
        final vec = new Vector.fromIterable(list);
        final vec2 = vec.removeLast();
        expect(vec, orderedEquals(list));
        expect(vec2, orderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8]));
      });
    });

    group('Iterable', () {
      List<int> src;
      Vector<int> vec;
      setUp(() {
        src = [1, -2, 3, -4, 5, -6];
        vec = new Vector.fromIterable(src);
      });

      test('length', () {
        expect(vec.length, 6);
      });

      test('first', () {
        expect(vec.first, 1);
      });
    });
  });
}
