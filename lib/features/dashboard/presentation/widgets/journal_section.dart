import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';

class JournalSection extends ConsumerWidget {
  const JournalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsyncValue = ref.watch(journalArticlesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDITORIAL DISPATCHES',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 3),
                Text(
                  'The Travelling Pen',
                  style: AppTypography.sectionTitle(color: AppColors.brown),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          articlesAsyncValue.when(
            data: (articles) {
              if (articles.isEmpty) return const SizedBox.shrink();
              final article = articles.first;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          article.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surfaceMuted),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  article.author.toUpperCase(),
                                  style: AppTypography.micro(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '·',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  article.readTime,
                                  style: AppTypography.micro(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.title,
                              style: AppTypography.editorialTitle(
                                color: AppColors.textPrimary,
                              ).copyWith(fontSize: 19),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.content,
                              style: AppTypography.bodyMedium(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
