import 'package:dsc26_flt_w03/ui/practice/cubit/practice_cubit.dart';
import 'package:dsc26_flt_w03/ui/practice/cubit/practice_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/api_failure.dart';
import '../../domain/models/question.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();

    // Load questions once when the screen starts.
    context.read<PracticeCubit>().loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeCubit, PracticeState>(
      builder: (context, state) {
        final cubit = context.read<PracticeCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Masaraat Practice'),
            actions: [
              IconButton(
                key: const Key('practice-refresh'),
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: state.isLoading ? null : cubit.loadQuestions,
              ),
            ],
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: _buildBody(state, cubit),
          ),
        );
      },
    );
  }

  Widget _buildBody(PracticeState state, PracticeCubit cubit) {
    switch (state.status) {
      case PracticeStatus.initial:
      case PracticeStatus.loading:
        return const Center(
          key: Key('practice-loading'),
          child: CircularProgressIndicator(),
        );

      case PracticeStatus.success:
        return _buildQuestionsList(state.questions);

      case PracticeStatus.empty:
        return const Center(
          key: Key('practice-empty'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "You've finished today's practice.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        );

      case PracticeStatus.failure:
        return _buildErrorView(state, cubit);
    }
  }

  Widget _buildQuestionsList(List<Question> questions) {
    return ListView.separated(
      key: const Key('practice-list'),
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = questions[index];

        return Card(
          key: Key('question-${question.id}'),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.stem,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...question.choices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(choice, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(PracticeState state, PracticeCubit cubit) {
    final isUnauthorized = state.failure is Unauthorized;

    return Center(
      key: const Key('practice-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'مش قادرين نحمل الأسئلة دلوقتي.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),

            if (isUnauthorized)
              ElevatedButton.icon(
                key: const Key('practice-signin'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in again to continue.'),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('تسجيل الدخول'),
              )
            else
              ElevatedButton.icon(
                key: const Key('practice-retry'),
                onPressed: cubit.loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('حاول مرة تانية'),
              ),
          ],
        ),
      ),
    );
  }
}
