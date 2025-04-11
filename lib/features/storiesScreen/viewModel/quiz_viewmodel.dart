// quiz_view_model.dart
import 'package:flutter/material.dart';
import '../model/stories_model.dart';

class QuizViewModel extends ChangeNotifier {
  final List<QuestionModel> questions;
  int currentQuestionIndex = 0;
  int? selectedOption;
  int score = 0;
  bool showResult = false;
  bool isCompleted = false;

  QuizViewModel({required this.questions});

  void selectOption(int optionIndex) {
    selectedOption = optionIndex;
    showResult = true;

    // Update score if correct
    if (optionIndex == questions[currentQuestionIndex].correctAnswer) {
      score++;
    }
    notifyListeners();
  }

  void nextQuestion() {
    currentQuestionIndex++;
    selectedOption = null;
    showResult = false;

    // If this was the last question, mark quiz as completed
    if (currentQuestionIndex >= questions.length) {
      isCompleted = true;
    }
    notifyListeners();
  }

  void restartQuiz() {
    currentQuestionIndex = 0;
    selectedOption = null;
    showResult = false;
    score = 0;
    isCompleted = false;
    notifyListeners();
  }

  double get percentageScore => (score / questions.length) * 100;
  bool get isPassed => percentageScore >= 60;
}