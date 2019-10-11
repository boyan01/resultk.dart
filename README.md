# Result.dart
[![Pub](https://img.shields.io/pub/v/resultk.svg)](https://pub.dartlang.org/packages/resultk)
[![CI](https://github.com/boyan01/resultk.dart/workflows/Dart%20CI/badge.svg)](https://github.com/boyan01/resultk.dart/actions)
[![codecov](https://codecov.io/gh/boyan01/resultk.dart/branch/master/graph/badge.svg)](https://codecov.io/gh/boyan01/resultk.dart)

This project is an implement of Kotlin/Result.kt for dart.


# Example

```dart

final Result<String> result = runCatching(()=> xxxx);
if(result.isSucess) {
    // do if succeed
}
result.onSuccess((v) {
    // do if succeed
});
result.onFailure((e) {
  // do if failure
});

```

# License

see license file.