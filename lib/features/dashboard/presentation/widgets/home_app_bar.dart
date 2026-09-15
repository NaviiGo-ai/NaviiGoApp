import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/brand/naviigo-mark-primary.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 28),
              ),
              const SizedBox(width: 8),
              Text(
                'NaviiGo',
                style: AppTypography.editorialTitle(
                  color: AppColors.brown,
                ).copyWith(fontSize: 22, letterSpacing: -0.3),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Search destinations',
                onPressed: () => context.push('/explore-discover'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Saved places',
                onPressed: () => context.push('/saved-places'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
