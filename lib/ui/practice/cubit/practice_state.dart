import 'package:dsc26_flt_w03/data/services/api_failure.dart';
import 'package:dsc26_flt_w03/domain/models/question.dart';

enum PracticeStatus { initial, loading, success, empty, failure }

class PracticeState {
  const PracticeState({
    this.status = PracticeStatus.initial,
    this.questions = const [],
    this.failure,
  });

  final PracticeStatus status;
  final List<Question> questions;
  final ApiFailure? failure;

  bool get isLoading => status == PracticeStatus.loading;
}
