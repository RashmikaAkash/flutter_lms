import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz_detail.dart';
import '../widgets/message_widget.dart';

class InstructorQuizDetailScreen extends StatefulWidget {
  const InstructorQuizDetailScreen({
    super.key,
    required this.quizId,
  });

  final String quizId;

  @override
  State<InstructorQuizDetailScreen> createState() =>
      _InstructorQuizDetailScreenState();
}

class _InstructorQuizDetailScreenState
    extends State<InstructorQuizDetailScreen> {
  final CourseService _courseService = CourseService();

  QuizDetail? _quizDetail;

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isCreatingQuestion = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizDetail = await _courseService.getInstructorQuiz(
        widget.quizId,
      );

      if (!mounted) return;

      setState(() {
        _quizDetail = quizDetail;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load quiz details. Please try again.';
      });
    }
  }

  Future<void> _editQuiz() async {
    final quiz = _quizDetail?.quiz;

    if (quiz == null) {
      return;
    }

    final passingScoreController = TextEditingController(
      text: quiz.passingScore.toString(),
    );

    final timeLimitController = TextEditingController(
      text: quiz.timeLimitMinutes.toString(),
    );

    final maxAttemptsController = TextEditingController(
      text: quiz.maxAttempts.toString(),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('Edit Quiz'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passingScoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Passing Score (%)',
                      hintText: 'Example: 60',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        value?.trim() ?? '',
                      );

                      if (parsed == null) {
                        return 'Enter a valid score';
                      }

                      if (parsed < 0 || parsed > 100) {
                        return 'Score must be between 0 and 100';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: timeLimitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Time Limit (minutes)',
                      hintText: 'Example: 10',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(
                        value?.trim() ?? '',
                      );

                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid time limit';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: maxAttemptsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Attempts',
                      hintText: 'Example: 3',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(
                        value?.trim() ?? '',
                      );

                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid attempt count';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  {
                    'passingScore': double.parse(
                      passingScoreController.text.trim(),
                    ),
                    'timeLimitMinutes': int.parse(
                      timeLimitController.text.trim(),
                    ),
                    'maxAttempts': int.parse(
                      maxAttemptsController.text.trim(),
                    ),
                  },
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      passingScoreController.dispose();
      timeLimitController.dispose();
      maxAttemptsController.dispose();
    });

    if (result == null) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _courseService.updateInstructorQuiz(
        quizId: widget.quizId,
        passingScore: result['passingScore'] as double,
        timeLimitMinutes: result['timeLimitMinutes'] as int,
        maxAttempts: result['maxAttempts'] as int,
      );

      if (!mounted) return;

      await _loadQuiz();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz updated successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update quiz. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _addQuestion() async {
    final quiz = _quizDetail?.quiz;

    if (quiz == null || quiz.isPublished) {
      return;
    }

    final formKey = GlobalKey<FormState>();

    final questionTextController = TextEditingController();
    final marksController = TextEditingController(text: '1');

    String questionType = 'SINGLE_CHOICE';

    final optionControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];

    String? correctOptionId = 'A';

    String optionIdForIndex(int index) {
      return String.fromCharCode(65 + index);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isTrueFalse = questionType == 'TRUE_FALSE';

            return AlertDialog(
              title: const Text('Add Question'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: questionTextController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Enter the question',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a question';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: questionType,
                        decoration: const InputDecoration(
                          labelText: 'Question Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'SINGLE_CHOICE',
                            child: Text('Single Choice'),
                          ),
                          DropdownMenuItem(
                            value: 'TRUE_FALSE',
                            child: Text('True / False'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            questionType = value;

                            if (questionType == 'TRUE_FALSE') {
                              correctOptionId = 'TRUE';
                            } else {
                              correctOptionId = 'A';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isTrueFalse) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Correct Answer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('True'),
                          value: 'TRUE',
                          groupValue: correctOptionId,
                          onChanged: (value) {
                            setDialogState(() {
                              correctOptionId = value;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('False'),
                          value: 'FALSE',
                          groupValue: correctOptionId,
                          onChanged: (value) {
                            setDialogState(() {
                              correctOptionId = value;
                            });
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Options',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${optionControllers.length}/10',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          optionControllers.length,
                          (index) {
                            final optionId = optionIdForIndex(index);

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Radio<String>(
                                    value: optionId,
                                    groupValue: correctOptionId,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        correctOptionId = value;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: optionControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Option $optionId',
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Enter option text';
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                  if (optionControllers.length > 2)
                                    IconButton(
                                      tooltip: 'Remove option',
                                      onPressed: () {
                                        final removedController =
                                            optionControllers[index];

                                        setDialogState(() {
                                          optionControllers.removeAt(index);

                                          if (correctOptionId == optionId) {
                                            correctOptionId =
                                                optionIdForIndex(0);
                                          }
                                        });

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          removedController.dispose();
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: optionControllers.length >= 10
                                ? null
                                : () {
                                    setDialogState(() {
                                      optionControllers.add(
                                        TextEditingController(),
                                      );
                                    });
                                  },
                            icon: const Icon(
                              Icons.add_circle_outline,
                            ),
                            label: const Text('Add Option'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: marksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Marks',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final marks = int.tryParse(
                            value?.trim() ?? '',
                          );

                          if (marks == null || marks <= 0) {
                            return 'Enter valid marks';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final options = isTrueFalse
                        ? <Map<String, String>>[
                            const {
                              'id': 'TRUE',
                              'text': 'True',
                            },
                            const {
                              'id': 'FALSE',
                              'text': 'False',
                            },
                          ]
                        : List.generate(
                            optionControllers.length,
                            (index) {
                              final optionId = optionIdForIndex(index);

                              return {
                                'id': optionId,
                                'text': optionControllers[index].text.trim(),
                              };
                            },
                          );

                    Navigator.pop(
                      dialogContext,
                      {
                        'questionText': questionTextController.text.trim(),
                        'questionType': questionType,
                        'options': options,
                        'correctOptionIds': [
                          correctOptionId!,
                        ],
                        'marks': int.parse(marksController.text.trim()),
                      },
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      questionTextController.dispose();
      marksController.dispose();

      for (final controller in optionControllers) {
        controller.dispose();
      }
    });

    if (result == null) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingQuestion = true;
    });

    try {
      await _courseService.createInstructorQuizQuestion(
        quizId: widget.quizId,
        questionText: result['questionText'] as String,
        questionType: result['questionType'] as String,
        options: List<Map<String, String>>.from(
          result['options'] as List,
        ),
        correctOptionIds: List<String>.from(result['correctOptionIds'] as List),
        marks: result['marks'] as int,
      );

      if (!mounted) {
        return;
      }

      await _loadQuiz();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question created successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create question. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingQuestion = false;
        });
      }
    }
  }

  Future<void> _publishQuiz() async {
    final quiz = _quizDetail?.quiz;

    if (quiz == null || quiz.isPublished) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Publish Quiz?'),
          content: const Text(
            'Once published, this quiz will become available '
            'according to the backend publishing rules. '
            'Draft question editing will no longer be available '
            'through this screen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _courseService.publishInstructorQuiz(
        widget.quizId,
      );

      if (!mounted) {
        return;
      }

      await _loadQuiz();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz published successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to publish quiz. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _editQuestionMarks(QuizQuestion question) async {
    final marksController = TextEditingController(
      text: question.marks.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Question Marks'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Marks',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final marks = int.tryParse(
                  value?.trim() ?? '',
                );

                if (marks == null || marks <= 0) {
                  return 'Enter valid marks';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  int.parse(
                    marksController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      marksController.dispose();
    });

    if (result == null) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _courseService.updateInstructorQuizQuestion(
        questionId: question.id,
        marks: result,
      );

      if (!mounted) {
        return;
      }

      await _loadQuiz();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question marks updated successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update question marks. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Question?'),
          content: const Text(
            'This question will be permanently deleted '
            'from the quiz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _courseService.deleteInstructorQuizQuestion(
        question.id,
      );

      if (!mounted) {
        return;
      }

      await _loadQuiz();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question deleted successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete question. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildQuizHeader() {
    final quiz = _quizDetail!.quiz;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.title.isEmpty ? 'Quiz' : quiz.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(quiz.description),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    quiz.isPublished
                        ? Icons.public_outlined
                        : Icons.drafts_outlined,
                    size: 18,
                  ),
                  label: Text(
                    quiz.isPublished ? 'PUBLISHED' : 'DRAFT',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                  ),
                  label: Text(
                    'Pass: '
                    '${quiz.passingScore.toStringAsFixed(0)}%',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.schedule_outlined,
                    size: 18,
                  ),
                  label: Text(
                    '${quiz.timeLimitMinutes} min',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.replay_outlined,
                    size: 18,
                  ),
                  label: Text(
                    '${quiz.maxAttempts} attempt(s)',
                  ),
                ),
                if (quiz.isPublished) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/instructor-quiz-attempts',
                                arguments: widget.quizId,
                              );
                            },
                      icon: const Icon(
                        Icons.people_outline,
                      ),
                      label: const Text('View Student Attempts'),
                    ),
                  ),
                ],
              ],
            ),
            if (quiz.section.title.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Section: ${quiz.section.title}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    QuizQuestion question,
    int index,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(question.questionType),
                ),
                Chip(
                  label: Text('${question.marks} mark(s)'),
                ),
                Chip(
                  label: Text('Order ${question.order}'),
                ),
              ],
            ),
            if (!_quizDetail!.quiz.isPublished) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        _isUpdating ? null : () => _editQuestionMarks(question),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Marks'),
                  ),
                  TextButton.icon(
                    onPressed:
                        _isUpdating ? null : () => _deleteQuestion(question),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
            if (question.options.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Options',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...question.options.map(
                (option) {
                  final isCorrect =
                      question.correctOptionIds.contains(option.id);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${option.id}. ${option.text}',
                          ),
                        ),
                        if (isCorrect)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load quiz',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadQuiz,
          ),
        ),
      );
    }

    final quizDetail = _quizDetail;

    if (quizDetail == null) {
      return const Center(
        child: MessageWidget(
          title: 'Quiz unavailable',
          message: 'Quiz details are not available.',
          type: MessageType.info,
        ),
      );
    }

    if (quizDetail.questions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadQuiz,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildQuizHeader(),
            const SizedBox(height: 16),
            const MessageWidget(
              title: 'No questions',
              message: 'This quiz does not have any questions yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuiz,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: quizDetail.questions.length + 1,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildQuizHeader();
          }

          return _buildQuestionCard(
            quizDetail.questions[index - 1],
            index - 1,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Details'),
        actions: [
          if (_quizDetail?.quiz.isPublished == false)
            IconButton(
              onPressed: _isLoading || _isUpdating || _isCreatingQuestion
                  ? null
                  : _publishQuiz,
              tooltip: 'Publish Quiz',
              icon: const Icon(Icons.publish_outlined),
            ),
          if (_quizDetail?.quiz.isPublished == false)
            IconButton(
              onPressed: _isLoading || _isUpdating || _isCreatingQuestion
                  ? null
                  : _addQuestion,
              tooltip: 'Add Question',
              icon: const Icon(Icons.add_circle_outline),
            ),
          if (_quizDetail?.quiz.isPublished == false)
            IconButton(
              onPressed: _isLoading || _isUpdating || _isCreatingQuestion
                  ? null
                  : _editQuiz,
              tooltip: 'Edit Quiz',
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
