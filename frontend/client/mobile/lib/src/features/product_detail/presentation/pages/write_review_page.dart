import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import '../../../../core/di/injection.dart';

class WriteReviewPage extends StatefulWidget {
  final String productId;
  final String orderItemId;
  final String? productName;
  final String? productImage;

  const WriteReviewPage({
    super.key,
    required this.productId,
    required this.orderItemId,
    this.productName,
    this.productImage,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          if (_selectedImages.length + images.length > 5) {
            // gioi han 5 anh
            final remainingCount = 5 - _selectedImages.length;
            _selectedImages.addAll(images.take(remainingCount));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chỉ được chọn tối đa 5 ảnh')),
            );
          } else {
            _selectedImages.addAll(images);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitReview(BuildContext context) {
    if (_selectedRating == 0) return;
    HapticFeedback.mediumImpact();

    context.read<ReviewCubit>().createReview(
      orderItemId: widget.orderItemId,
      productId: widget.productId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
      imagePaths: _selectedImages.map((e) => e.path).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<ReviewCubit>(),
      child: BlocListener<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state is ReviewActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) {
            final state = context.watch<ReviewCubit>().state;
            final isSubmitting = state is ReviewLoading;

            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: AppBar(
                backgroundColor: colorScheme.surface,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  'Viết đánh giá',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chất lượng sản phẩm',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _selectedRating = index + 1,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        scale: _selectedRating == index + 1
                                            ? 1.2
                                            : 1.0,
                                        curve: Curves.easeOutCubic,
                                        child: Icon(
                                          index < _selectedRating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 44,
                                          color: index < _selectedRating
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              'Nội dung đánh giá',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _commentController,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Chia sẻ trải nghiệm của bạn về sản phẩm này...',
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Hình ảnh (Tối đa 5)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // add images
                                  if (_selectedImages.length < 5)
                                    GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHigh
                                              .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outlineVariant
                                                .withValues(alpha: 0.4),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.camera,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ...List.generate(_selectedImages.length, (
                                    index,
                                  ) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      width: 80,
                                      height: 80,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.file(
                                              File(_selectedImages[index].path),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // submit btn
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: ElevatedButton(
                        onPressed: _selectedRating > 0 && !isSubmitting
                            ? () => _submitReview(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.onSurface,
                          foregroundColor: colorScheme.surface,
                          disabledBackgroundColor: colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          disabledForegroundColor: colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.surface,
                                  ),
                                ),
                              )
                            : const Text(
                                'Gửi đánh giá',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
