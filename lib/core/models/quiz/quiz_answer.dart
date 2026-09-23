class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.selectedOptionIds,
  });

  final String questionId;
  final List<String> selectedOptionIds;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionIds': selectedOptionIds,
    };
  }
}
