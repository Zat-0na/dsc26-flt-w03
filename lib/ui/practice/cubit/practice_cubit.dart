import 'package:dsc26_flt_w03/data/repositories/practice_repository.dart';
import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dsc26_flt_w03/utils/result.dart';
import 'practice_state.dart';

class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit({
    required PracticeRepository repository,
    required String studentId,
  }) : _repository = repository,
       _studentId = studentId,
       super(const PracticeState());

  final PracticeRepository _repository;
  final String _studentId;

  Future<void> loadQuestions() async {
    // Prevent multiple requests while one is already running.
    if (state.isLoading || isClosed) return;

    // Show the loading state.
    emit(const PracticeState(status: PracticeStatus.loading));

    try {
      // Fetch questions from the repository.
      final result = await _repository.nextQuestions(_studentId);

      // The Cubit may have been closed while waiting.
      if (isClosed) return;

      if (result is Ok<List<Question>>) {
        final questions = result.value;

        if (questions.isEmpty) {
          emit(const PracticeState(status: PracticeStatus.empty));
        } else {
          emit(
            PracticeState(status: PracticeStatus.success, questions: questions),
          );
        }
      } else if (result is Err<List<Question>>) {
        emit(
          PracticeState(
            status: PracticeStatus.failure,
            failure: result.failure,
          ),
        );
      }
    } catch (_) {
      // Do not expose technical exception details to the UI.
      if (isClosed) return;

      emit(const PracticeState(status: PracticeStatus.failure));
    }
  }
}
