class AppError {
  final String message;
  final String? code;
  final Object? originalError;

  AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

abstract class Result<T, E extends AppError> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => isSuccess ? (this as Success<T, E>).value : null;
  E? get errorOrNull => isFailure ? (this as Failure<T, E>).error : null;

  R fold<R>(R Function(E) onFailure, R Function(T) onSuccess) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).value);
    } else {
      return onFailure((this as Failure<T, E>).error);
    }
  }
}

class Success<T, E extends AppError> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E extends AppError> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
