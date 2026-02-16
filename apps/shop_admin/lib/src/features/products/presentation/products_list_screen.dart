import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import '../application/products_provider.dart';
import '../../auth/application/auth_provider.dart';

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final productsAsync = ref.watch(productsProvider);

    // Auth Guard
    if (tenant == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view products')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Off-White Background
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata oluştu: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (products) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Silver App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                title: Text(
                  'Ürünler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      // Settings action placeholder
                    },
                    icon: const Icon(Icons.settings_outlined, color: Colors.black),
                    tooltip: 'Ayarlar',
                  ),
                  IconButton(
                    onPressed: () {
                      // QR Code action placeholder
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.black),
                    tooltip: 'QR Kod',
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // 2. Category Chips (Horizontal Scroll)
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  color: const Color(0xFFF9FAFB),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _CategoryChip(label: 'Tümü', isSelected: true),
                      const SizedBox(width: 8),
                      _CategoryChip(label: 'Yiyecekler', isSelected: false),
                      const SizedBox(width: 8),
                      _CategoryChip(label: 'İçecekler', isSelected: false),
                      const SizedBox(width: 8),
                      _CategoryChip(label: 'Tatlılar', isSelected: false),
                      const SizedBox(width: 8),
                      _CategoryChip(label: 'Diğer', isSelected: false),
                    ],
                  ),
                ),
              ),

              // 3. Product List
              if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz ürün eklenmemiş',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProductCard(
                            product: product,
                            onEdit: () => context.go('/products/${product.id}'),
                            onToggleStatus: (val) {
                              ref.read(productsProvider.notifier).updateProduct(
                                    product.copyWith(isAvailable: val),
                                  );
                            },
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
              
              // Bottom padding for FAB
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Ürün Ekle'),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleStatus;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Image / Icon
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: product.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrl == null
                      ? Icon(Icons.fastfood, color: Colors.grey.shade400)
                      : null,
                ),
                
                const SizedBox(width: 16),

                // 2. Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active/Passive Switch
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: product.isAvailable,
                        activeColor: Colors.black,
                        onChanged: onToggleStatus,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Edit Button
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
