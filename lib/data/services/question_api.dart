import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';
import 'api_failure.dart';

/// One call to the Masaraat questions API. Holds no state and never retries.
///
/// Keep the constructor and the signature of [fetchNext] exactly.
class QuestionApi {
  QuestionApi({
    required http.Client client,
    required Uri baseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout;

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  /// GET {baseUrl}/v1/students/{studentId}/next-questions?limit={limit}
  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    // Validate limit before sending any request.
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 50');
    }

    // Preserve the existing base URL path and remove its trailing slash.
    final pathSegments = _baseUrl.pathSegments.toList();

    if (pathSegments.isNotEmpty && pathSegments.last.isEmpty) {
      pathSegments.removeLast();
    }

    // Build the URL using pathSegments to encode studentId as one segment.
    final uri = _baseUrl.replace(
      pathSegments: [
        ...pathSegments,
        'v1',
        'students',
        studentId,
        'next-questions',
      ],
      queryParameters: {'limit': limit.toString()},
    );

    late http.Response response;

    // Send the request and handle network failures.
    try {
      response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      return const Err(TimedOut());
    } on http.ClientException {
      return const Err(Offline());
    }

    // Handle HTTP status codes.
    switch (response.statusCode) {
      case 200:
        return _parseResponse(response);

      case 401:
        return const Err(Unauthorized());

      case 404:
        return const Err(NotFound());

      case 429:
        final retryAfterHeader = response.headers['retry-after'];

        // Accept whole numbers only.
        final retryAfter =
            retryAfterHeader != null &&
                RegExp(r'^\d+$').hasMatch(retryAfterHeader)
            ? int.tryParse(retryAfterHeader)
            : null;

        return Err(RateLimited(Duration(seconds: retryAfter ?? 5)));

      default:
        if (response.statusCode >= 500 && response.statusCode <= 599) {
          return Err(ServerError(response.statusCode));
        }

        return Err(UnexpectedStatus(response.statusCode));
    }
  }

  /// Parses a successful response into a list of Questions.
  /// Invalid JSON or invalid fields return BadResponse instead of throwing.
  Result<List<Question>> _parseResponse(http.Response response) {
    try {
      // Always decode bytes as UTF-8, regardless of response headers.
      final decodedBody = utf8.decode(response.bodyBytes);

      final decodedJson = jsonDecode(decodedBody);

      // The top-level JSON must be an object.
      if (decodedJson is! Map) {
        throw const FormatException('Response must be a JSON object');
      }

      // The response must contain a questions list.
      final rawQuestions = decodedJson['questions'];

      if (rawQuestions is! List) {
        throw const FormatException('Missing or invalid questions list');
      }

      final questions = <Question>[];

      for (final item in rawQuestions) {
        if (item is! Map) {
          throw const FormatException('Each question must be a JSON object');
        }

        // Convert each JSON object to the expected map type.
        final questionJson = Map<String, Object?>.from(item);

        questions.add(Question.fromJson(questionJson));
      }

      return Ok(questions);
    } catch (error) {
      // Malformed JSON, invalid UTF-8, or invalid question data.
      return Err(BadResponse(error.toString()));
    }
  }
}
