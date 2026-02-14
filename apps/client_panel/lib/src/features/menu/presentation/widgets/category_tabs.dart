/// Category Tabs Header
/// 
/// Horizontal scrolling category tabs that stick to the top.
library;

import 'package:flutter/material.dart';
import '../../domain/menu_models.dart';

/// Sticky category tabs header
class CategoryTabsHeader extends StatelessWidget {
  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryTabsHeader({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 56,
      color: colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          // "All" Tab
          if (index == 0) {
            final isSelected = selectedCategoryId == null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: isSelected,
                label: const Text('Tümü'),
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                showCheckmark: false,
                onSelected: (_) => onCategorySelected(null),
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = category.id == selectedCategoryId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(category.name),
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.primary,
              checkmarkColor: colorScheme.onPrimary,
              showCheckmark: false,
              onSelected: (_) => onCategorySelected(category.id),
            ),
          );
        },
      ),
    );
  }
}

/// Sliver delegate for sticky category header
class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CategoryTabsHeader(
      categories: categories,
      selectedCategoryId: selectedCategoryId,
      onCategorySelected: onCategorySelected,
    );
  }

  @override
  bool shouldRebuild(CategoryHeaderDelegate oldDelegate) {
    return selectedCategoryId != oldDelegate.selectedCategoryId ||
        categories != oldDelegate.categories;
  }
}
