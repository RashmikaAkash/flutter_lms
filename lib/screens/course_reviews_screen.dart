import 'package:flutter/material.dart';

import '../core/course/review_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_review.dart';
import '../core/models/profile/profile_service.dart';
import '../widgets/message_widget.dart';

class CourseReviewsScreen extends StatefulWidget {
  const CourseReviewsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.isEnrolled,
  });

  final String courseId;
  final String courseTitle;
  final bool isEnrolled;

  @override
  State<CourseReviewsScreen> createState() => _CourseReviewsScreenState();
}

class _CourseReviewsScreenState extends State<CourseReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _commentController = TextEditingController();

  List<CourseReview> _reviews = [];
  CourseReview? _myReview;
  bool _isLoading = true;
  bool _isSaving = false;
  int _rating = 5;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await _profileService.getFullProfile();
      final reviews = <CourseReview>[];
      var page = 1;
      var hasNextPage = true;
      CourseReview? myReview;

      while (hasNextPage) {
        final result = await _reviewService.getCourseReviews(
          widget.courseId,
          page: page,
          limit: 100,
        );
        reviews.addAll(result.reviews);
        myReview ??= result.reviews.cast<CourseReview?>().firstWhere(
              (review) => review?.studentId == currentUser.user.id,
              orElse: () => null,
            );
        hasNextPage = result.pagination.hasNextPage && myReview == null;
        page++;
      }

      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _myReview = myReview;
        if (myReview != null) {
          _rating = myReview.rating;
          _commentController.text = myReview.comment ?? '';
        } else {
          _rating = 5;
          _commentController.clear();
        }
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load course reviews. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReview() async {
    if (!widget.isEnrolled || _isSaving) return;
    final comment = _commentController.text.trim();
    if (comment.length > 1500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Review comments can be up to 1500 characters.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_myReview == null) {
        await _reviewService.createReview(
          courseId: widget.courseId,
          rating: _rating,
          comment: comment.isEmpty ? null : comment,
        );
      } else {
        await _reviewService.updateReview(
          reviewId: _myReview!.id,
          rating: _rating,
          comment: comment,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_myReview == null ? 'Review submitted.' : 'Review updated.'),
        ),
      );
      await _loadReviews();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to save review. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteMyReview() async {
    final review = _myReview;
    if (review == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This will permanently remove your course review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _reviewService.deleteReview(review.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
      await _loadReviews();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to delete review. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildReviewEditor() {
    if (!widget.isEnrolled) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Enroll in this course to write a review.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _myReview == null ? 'Write a review' : 'Your review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Your rating', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star of 5 stars',
                    onPressed:
                        _isSaving ? null : () => setState(() => _rating = star),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _rating
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.outline,
                      size: 32,
                    ),
                  ),
                Text('$_rating / 5'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              enabled: !_isSaving,
              maxLength: 1500,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveReview,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(
                      _myReview == null ? 'Submit review' : 'Save changes'),
                ),
                if (_myReview != null)
                  TextButton.icon(
                    onPressed: _isSaving ? null : _deleteMyReview,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(CourseReview review) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.studentName.isEmpty ? 'Student' : review.studentName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 3),
                Text('${review.rating} / 5'),
              ],
            ),
            if (review.comment?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Reviews')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MessageWidget(
                      title: 'Unable to load reviews',
                      message: _errorMessage!,
                      type: MessageType.error,
                      actionLabel: 'Retry',
                      onActionPressed: _loadReviews,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        widget.courseTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildReviewEditor(),
                      const SizedBox(height: 20),
                      Text(
                        'Learner reviews',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_reviews.isEmpty)
                        const MessageWidget(
                          title: 'No reviews yet',
                          message:
                              'Be the first learner to review this course.',
                          type: MessageType.info,
                        )
                      else
                        ..._reviews.map(_buildReviewCard),
                    ],
                  ),
                ),
    );
  }
}
