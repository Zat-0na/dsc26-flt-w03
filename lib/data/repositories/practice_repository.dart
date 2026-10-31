import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/api_failure.dart';
import '../services/question_api.dart';
/// The source of truth for practice questions. Owns the retry policy.
///
/// Keep the constructor and the signature of nextQuestions exactly.
class PracticeRepository {
  PracticeRepository({
    required QuestionApi api,
    required Future<void> Function(Duration) sleep,
    int maxRetries = 2,
  }) : _api = api,
       _sleep = sleep,
       _maxRetries = maxRetries;

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    var retryCount = 0;

    while (true) {
      final result = await _api.fetchNext(studentId: studentId);

      if (result is Ok<List<Question>>) {
        return result;
      }

      final failure = (result as Err<List<Question>>).failure;

      if (!failure.isTransient) {
        return result;
      }

      if (retryCount >= _maxRetries) {
        return result;
      }

      final Duration waitDuration;

      if (failure is RateLimited) {
        waitDuration = failure.retryAfter > const Duration(seconds: 30)
            ? const Duration(seconds: 30)
            : failure.retryAfter;
      } else {
        waitDuration = Duration(seconds: 1 << retryCount);
      }

      await _sleep(waitDuration);

      retryCount++;
    }
  }
}
