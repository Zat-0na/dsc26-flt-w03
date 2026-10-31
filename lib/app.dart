import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/practice_repository.dart';
import 'ui/practice/cubit/practice_cubit.dart';
import 'ui/practice/practice_screen.dart';

Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return BlocProvider(
    create: (context) =>
        PracticeCubit(repository: repository, studentId: studentId),
        
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PracticeScreen(),
    ),
  );
}
