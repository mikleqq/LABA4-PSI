/// Errors that the data layer can raise. Every one of them carries a
/// human-readable Russian message that the UI shows as is.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No network, DNS failure, timeout, connection reset.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Нет подключения к сети или сервер не отвечает.',
  ]);
}

/// The source answered, but with a non-200 status code.
class SourceException extends AppException {
  const SourceException(this.statusCode, [String? details])
    : super(
        details == null
            ? 'Источник данных недоступен (код $statusCode).'
            : 'Источник данных вернул ошибку (код $statusCode): $details',
      );

  final int statusCode;
}

/// The response body is not the JSON we expect.
class DataFormatException extends AppException {
  const DataFormatException(String details)
    : super('Некорректные данные от источника: $details');
}

/// The response is well-formed but contains no data.
class EmptyDataException extends AppException {
  const EmptyDataException([super.message = 'Источник вернул пустой ответ.']);
}
