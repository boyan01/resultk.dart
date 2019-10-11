import 'package:meta/meta.dart';

/// A discriminated union that encapsulates successful outcome with a value of type [T]
/// or a failure with an arbitrary [Throwable] exception.
class Result<T> {
  final dynamic _value;

  Result._internal(this._value);

  /// Returns an instance that encapsulates the given [value] as successful value.
  factory Result.success(T value) => Result._internal(value);

  /// Returns an instance that encapsulates the given [exception] as failure.
  factory Result.failure(dynamic exception, [StackTrace stackTrace]) =>
      Result._internal(_Failure(CaughtException(exception, stackTrace)));

  /// Returns `true` if this instance represents successful outcome.
  /// In this case [isFailure] returns `false`.
  bool get isSuccess => _value is! _Failure;

  /// Returns `true` if this instance represents failed outcome.
  /// In this case [isSuccess] returns `false`.
  bool get isFailure => _value is _Failure;

  /// Returns the encapsulated value if this instance represents [success][Result.isSuccess] or `null`
  /// if it is [failure][Result.isFailure].
  ///
  /// This function is shorthand for `getOrElse((e) => null)` (see [getOrElse]) or
  /// `fold(onSuccess: (v) => v, onFailure: (e) => null)` (see [fold]).
  T getOrNull() {
    if (isFailure) {
      return null;
    } else {
      return _value as T;
    }
  }

  /// Returns the encapsulated exception if this instance represents [failure][isFailure] or `null`
  /// if it is [success][isSuccess].
  ///
  /// This function is shorthand for `fold(onSuccess: (value) => null, onFailure: (e) => e)` (see [fold]).
  CaughtException exceptionOrNull() {
    if (_value is _Failure) {
      return _value.exception;
    } else {
      return null;
    }
  }

  @override
  String toString() {
    if (_value is _Failure) {
      return _value.toString(); // "Failure($exception)"
    } else {
      return 'success($_value)';
    }
  }

  // ext functions

  /// Throws exception if the result is failure. This internal function minimizes
  /// inlined bytecode for [getOrThrow] and makes sure that in the future we can
  /// add some exception-augmenting logic here (if needed).
  void throwOnFailure() {
    // can not rethrow stacktrace because https://github.com/dart-lang/sdk/issues/10297
    if (_value is _Failure) throw (_value as _Failure).exception.exception;
  }

  /// Returns the encapsulated value if this instance represents [success][Result.isSuccess] or throws the encapsulated exception
  /// if it is [failure][Result.isFailure].
  ///
  /// This function is shorthand for `getOrElse((e) => throw e.exception)` (see [getOrElse]).
  T getOrThrow() {
    throwOnFailure();
    return _value as T;
  }

  /// Returns the encapsulated value if this instance represents [success][Result.isSuccess] or the
  /// result of [onFailure] function for encapsulated exception if it is [failure][Result.isFailure].
  ///
  /// Note, that an exception thrown by [onFailure] function is rethrown by this function.
  ///
  /// This function is shorthand for `fold(onSuccess : (v) => v, onFailure : onFailure)` (see [fold]).
  T getOrElse(T onFailure(CaughtException exception)) {
    final exception = exceptionOrNull();
    if (exception == null) {
      return _value as T;
    } else {
      return onFailure(exception);
    }
  }

  /// Returns the encapsulated value if this instance represents [success][Result.isSuccess] or the
  /// [defaultValue] if it is [failure][Result.isFailure].
  ///
  /// This function is shorthand for `getOrElse((e) => defaultValue)` (see [getOrElse]).
  T getOrDefault(T defaultValue) {
    if (isFailure) return defaultValue;
    return _value as T;
  }

  /// Returns the the result of [onSuccess] for encapsulated value if this instance represents [success][Result.isSuccess]
  /// or the result of [onFailure] function for encapsulated exception if it is [failure][Result.isFailure].
  ///
  /// Note, that an exception thrown by [onSuccess] or by [onFailure] function is rethrown by this function.
  R fold<R>({
    @required R onSuccess(T value),
    @required R onFailure(CaughtException exception),
  }) {
    assert(onSuccess != null, "onSuccess callback is required");
    assert(onFailure != null, "onFailure callback is required");

    final exception = exceptionOrNull();
    if (exception == null) {
      return onSuccess(_value as T);
    } else {
      return onFailure(exception);
    }
  }

  // transformation

  /// Returns the encapsulated result of the given [transform] function applied to encapsulated value
  /// if this instance represents [success][Result.isSuccess] or the
  /// original encapsulated exception if it is [failure][Result.isFailure].
  ///
  /// Note, that an exception thrown by [transform] function is rethrown by this function.
  /// See [mapCatching] for an alternative that encapsulates exceptions.
  Result<R> map<R>(R transform(T value)) {
    if (isSuccess) {
      return Result.success(transform(_value as T));
    } else {
      return Result._internal(_value);
    }
  }

  /// Returns the encapsulated result of the given [transform] function applied to encapsulated value
  /// if this instance represents [success][Result.isSuccess] or the
  /// original encapsulated exception if it is [failure][Result.isFailure].
  ///
  /// Any exception thrown by [transform] function is caught, encapsulated as a failure and returned by this function.
  /// See [map] for an alternative that rethrows exceptions.
  Result<R> mapCatching<R>(R transform(T value)) {
    if (isSuccess) {
      return runCatching(() => transform(_value as T));
    } else {
      return Result._internal(_value);
    }
  }

  /// Returns the encapsulated result of the given [transform] function applied to encapsulated exception
  /// if this instance represents [failure][Result.isFailure] or the
  /// original encapsulated value if it is [success][Result.isSuccess].
  ///
  /// Note, that an exception thrown by [transform] function is rethrown by this function.
  /// See [recoverCatching] for an alternative that encapsulates exceptions.
  Result<T> recover(T transform(CaughtException exception)) {
    final e = exceptionOrNull();
    if (e == null) {
      return this;
    }
    return Result.success(transform(e));
  }

  /// Returns the encapsulated result of the given [transform] function applied to encapsulated exception
  /// if this instance represents [failure][Result.isFailure] or the
  /// original encapsulated value if it is [success][Result.isSuccess].
  ///
  /// Any exception thrown by [transform] function is caught, encapsulated as a failure and returned by this function.
  /// See [recover] for an alternative that rethrows exceptions.
  Result<T> recoverCatching(T transform(CaughtException exception)) {
    final e = exceptionOrNull();
    if (e == null) {
      return this;
    }
    return runCatching(() => transform(e));
  }

  // "peek" onto value/exception and pipe

  /// Performs the given [action] on encapsulated exception if this instance represents [failure][Result.isFailure].
  /// Returns the original `Result` unchanged.
  Result<T> onFailure(void action(CaughtException exception)) {
    final e = exceptionOrNull();
    if (e != null) {
      action(e);
    }
    return this;
  }

  /// Performs the given [action] on encapsulated value if this instance represents [success][Result.isSuccess].
  /// Returns the original `Result` unchanged.
  Result<T> onSuccess(void action(T value)) {
    if (isSuccess) {
      action(_value as T);
    }
    return this;
  }
}

/// Calls the specified function [block] and returns its encapsulated result if invocation was successful,
/// catching and encapsulating any thrown exception as a failure.
Result<R> runCatching<R>(R block()) {
  try {
    return Result.success(block());
  } catch (e, stacktrace) {
    return Result.failure(e, stacktrace);
  }
}

class _Failure {
  final CaughtException exception;

  _Failure(this.exception);

  @override
  String toString() {
    return "Failure($exception)";
  }
}

/// An exception that was caught and has an associated stack trace.
class CaughtException implements Exception {
  /// The exception that was caught.
  final Object exception;

  StackTrace _stackTrace;

  /// The stack trace associated with the exception.
  StackTrace get stackTrace => _stackTrace;

  /// Initialize a newly created caught exception to have the given [exception]
  /// and [stackTrace].
  CaughtException(this.exception, stackTrace) {
    if (stackTrace == null) {
      try {
        throw this;
      } catch (_, st) {
        stackTrace = st;
      }
    }
    this._stackTrace = stackTrace;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    _writeOn(buffer);
    return buffer.toString();
  }

  /// Write a textual representation of the caught exception and its associated
  /// stack trace.
  void _writeOn(StringBuffer buffer) {
    buffer.writeln(exception.toString());
    if (_stackTrace != null) {
      buffer.writeln(_stackTrace.toString());
    }
  }
}
