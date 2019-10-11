import 'package:result/result.dart';
import 'package:test/test.dart';

void main() {
  test("sucess value", () {
    final value = "Hello";
    final Result<String> result = Result.success(value);
    result.onSuccess((v) {
      expect(v, equals(value));
    });
    result.onFailure((e) {
      fail("never be invoked");
    });
    final a = result.fold(onSuccess: (v) => v, onFailure: (e) => null);
    expect(a, equals(value));

    final b = result.getOrElse((e) {
      fail("never be invoked");
    });
    expect(b, equals(value));

    final c = result.getOrDefault("World");
    expect(c, equals(value));

    expect(result.exceptionOrNull(), isNull);
    expect(result.getOrThrow(), equals(value));

    try {
      result.throwOnFailure();
    } catch (e) {
      fail("never be invoked");
    }
  });

  test("mapping", () {
    final result = Result.success("Hello");
    final result2 = result.map((v) {
      return "World";
    });
    expect(result2.isSuccess, isTrue);
    expect(result2.getOrThrow(), equals("World"));

    try {
      result.map((v) {
        throw Exception("error");
      });
      fail("never be invoked!");
    } catch (e) {
      // ignore
    }

    final result3 = result.mapCatching((v) {
      return "World";
    });
    expect(result3.isSuccess, isTrue);
    expect(result3.getOrThrow(), equals("World"));

    final result4 = result.mapCatching((v) {
      throw "error";
    });
    expect(result4.isSuccess, isFalse);
    expect(result4.exceptionOrNull().exception, equals("error"));
  });

  test("error value", () {
    final error = "error";
    final Result<String> result = Result.failure(error);
    expect(result.exceptionOrNull(), isNotNull);
    expect(result.getOrNull(), isNull);

    expect(result.getOrDefault("Hello."), equals("Hello."));
    expect(result.getOrElse((e) {
      expect(e.exception, equals(error));
      return "World.";
    }), equals("World."));

    try {
      result.getOrThrow();
      fail("never be invoked");
    } catch (e) {
      // ignore
    }

    result.onSuccess((v) {
      fail("never be invoked");
    });
    result.onFailure((e) {
      expect(e.exception, equals(error));
    });
  });
}
