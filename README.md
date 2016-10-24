# Immutable.dart
A mininimal set of collections which are
* Immutable: collections cannot be mutated, instead returning new collections when items are added or removed.
* Persistent: collections share unchanged data across versions.





### Features
* `==` can be used to check if a Collection has changed.  This allows efficient update methods in [AngularDart 2](https://angular.io/dart) , [Flutter](https://flutter.io/), and [OverReact](https://workiva.github.io/over_react/).
* Producing a new collection is approximately O(logN), instead of O(N) for a full copy.
* Field access is Log<sub>32</sub>N, which is only marginally slower than constant time for reasonably sized (less than 100 trillion elements) collections.



## Examples

### Vector

Creating a Vector from an Iterable.
```dart
	final vec = new Vector.fromIterable(new List.generate(64000, (i) => i));
	print(vec[2000]); // prints "2000"
```

Transforming a Vector using Iterable methods.
```dart
	final sum = vec
    	.map((i) => 2 * i)
        .filter((i) => i % 2 == 0)
        .fold(0, (x, y) => x + y));
```

Using a Vector as an immutable Stack
```dart
	var stack = new Vector.empty();
    stack = stack.append(2);
    stack = stack.append(3);
    stack = stack.append(4);
    while (stack.isNotEmpty) {
    	print(stack.last); // prints "4", then "3", then "2"
        stack = stack.removeLast();
    }
    print(stack.length); // prints "0"
```


## Todo
* Support transients for efficient mutations (internally and externally)
* Finish Vector, Dictionary, and LazyIterable APIs (sort, flatMap?)
* Large benchmark tests
