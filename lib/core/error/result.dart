sealed class Result<T, F extends Failure> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(F failure) failure,
  });

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is Error<T, F>;
}

class Success<T, F extends Failure> extends Result<T, F> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(F failure) failure,
  }) {
    return success(data);
  }
}

class Error<T, F extends Failure> extends Result<T, F> {
  final F failure;
  const Error(this.failure);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(F failure) failure,
  }) {
    return failure(this.failure);
  }
}

sealed class Failure {
  final String message;
  final dynamic originalError;

  const Failure(this.message, [this.originalError]);

  @override
  String toString() =>
      'Failure: $message ${originalError != null ? "($originalError)" : ""}';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network connection failed',
    super.originalError,
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed',
    super.originalError,
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Cache operation failed',
    super.originalError,
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unknown error occurred',
    super.originalError,
  ]);
}
