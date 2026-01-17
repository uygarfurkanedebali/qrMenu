/// Category Tabs Header
/// 
/// Horizontal scrolling category tabs that stick to the top.
library;

import 'package:flutter/material.dart';
import '../../domain/menu_models.dart';

/// Sticky category tabs header
class CategoryTabsHeader extends StatelessWidget {
  final List<MenuCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const CategoryTabsHeader({
    super.key,
    required this.categories,
    required this.selectedIndex,
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
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedIndex;

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
              onSelected: (_) => onCategorySelected(index),
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
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  CategoryHeaderDelegate({
    required this.categories,
    required this.selectedIndex,
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
      selectedIndex: selectedIndex,
      onCategorySelected: onCategorySelected,
    );
  }

  @override
  bool shouldRebuild(CategoryHeaderDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex ||
        categories != oldDelegate.categories;
  }
}
