/// Fake Menu Repository
/// 
/// Provides mock menu data for each tenant.
/// Each tenant has distinct categories and products.
library;

import '../domain/menu_models.dart';

/// Repository interface for menu operations
abstract class MenuRepository {
  /// Gets all categories with products for a tenant
  Future<List<MenuCategory>> getMenuByTenantId(String tenantId);
}

/// Mock implementation with tenant-specific menu data
class FakeMenuRepository implements MenuRepository {
  @override
  Future<List<MenuCategory>> getMenuByTenantId(String tenantId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    switch (tenantId) {
      case 'tenant-001': // Kebab Shop
        return _getKebabShopMenu(tenantId);
      case 'tenant-002': // Coffee Shop
        return _getCoffeeShopMenu(tenantId);
      case 'tenant-003': // Sushi Spot
        return _getSushiSpotMenu(tenantId);
      default:
        return [];
    }
  }

  List<MenuCategory> _getKebabShopMenu(String tenantId) {
    return [
      MenuCategory(
        id: 'cat-kebab-1',
        tenantId: tenantId,
        name: 'Kebabs',
        description: 'Traditional Turkish kebabs grilled to perfection',
        sortOrder: 0,
        products: [
          MenuProduct(
            id: 'prod-k1',
            tenantId: tenantId,
            categoryId: 'cat-kebab-1',
            name: 'Adana Kebab',
            description: 'Spicy minced meat kebab with traditional seasonings',
            price: 14.99,
            imageUrl: 'https://placehold.co/200x200/D32F2F/FFFFFF?text=Adana',
            isPopular: true,
            tags: ['Spicy', 'Grilled'],
          ),
          MenuProduct(
            id: 'prod-k2',
            tenantId: tenantId,
            categoryId: 'cat-kebab-1',
            name: 'Iskender Kebab',
            description: 'Döner meat on pita bread with tomato sauce and yogurt',
            price: 16.99,
            imageUrl: 'https://placehold.co/200x200/D32F2F/FFFFFF?text=Iskender',
            isPopular: true,
            tags: ['Signature', 'Creamy'],
          ),
          MenuProduct(
            id: 'prod-k3',
            tenantId: tenantId,
            categoryId: 'cat-kebab-1',
            name: 'Shish Kebab',
            description: 'Marinated lamb cubes grilled on skewers',
            price: 13.99,
            imageUrl: 'https://placehold.co/200x200/D32F2F/FFFFFF?text=Shish',
            tags: ['Grilled'],
          ),
          MenuProduct(
            id: 'prod-k4',
            tenantId: tenantId,
            categoryId: 'cat-kebab-1',
            name: 'Chicken Kebab',
            description: 'Tender chicken pieces with herbs and spices',
            price: 11.99,
            imageUrl: 'https://placehold.co/200x200/D32F2F/FFFFFF?text=Chicken',
            tags: ['Mild'],
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-kebab-2',
        tenantId: tenantId,
        name: 'Wraps & Döner',
        description: 'Quick bites wrapped to go',
        sortOrder: 1,
        products: [
          MenuProduct(
            id: 'prod-w1',
            tenantId: tenantId,
            categoryId: 'cat-kebab-2',
            name: 'Döner Wrap',
            description: 'Classic döner meat in lavash with vegetables',
            price: 9.99,
            imageUrl: 'https://placehold.co/200x200/FFC107/000000?text=Doner',
            isPopular: true,
          ),
          MenuProduct(
            id: 'prod-w2',
            tenantId: tenantId,
            categoryId: 'cat-kebab-2',
            name: 'Falafel Wrap',
            description: 'Crispy falafel with hummus and vegetables',
            price: 8.99,
            imageUrl: 'https://placehold.co/200x200/FFC107/000000?text=Falafel',
            tags: ['Vegetarian'],
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-kebab-3',
        tenantId: tenantId,
        name: 'Drinks',
        description: 'Refreshing beverages',
        sortOrder: 2,
        products: [
          MenuProduct(
            id: 'prod-d1',
            tenantId: tenantId,
            categoryId: 'cat-kebab-3',
            name: 'Ayran',
            description: 'Traditional Turkish yogurt drink',
            price: 2.99,
            imageUrl: 'https://placehold.co/200x200/FFFFFF/000000?text=Ayran',
          ),
          MenuProduct(
            id: 'prod-d2',
            tenantId: tenantId,
            categoryId: 'cat-kebab-3',
            name: 'Turkish Tea',
            description: 'Hot black tea served in traditional glass',
            price: 1.99,
            imageUrl: 'https://placehold.co/200x200/B71C1C/FFFFFF?text=Tea',
          ),
        ],
      ),
    ];
  }

  List<MenuCategory> _getCoffeeShopMenu(String tenantId) {
    return [
      MenuCategory(
        id: 'cat-coffee-1',
        tenantId: tenantId,
        name: 'Hot Coffees',
        description: 'Expertly crafted hot beverages',
        sortOrder: 0,
        products: [
          MenuProduct(
            id: 'prod-c1',
            tenantId: tenantId,
            categoryId: 'cat-coffee-1',
            name: 'Signature Latte',
            description: 'Espresso with steamed milk and house vanilla',
            price: 5.49,
            imageUrl: 'https://placehold.co/200x200/795548/FFFFFF?text=Latte',
            isPopular: true,
            tags: ['Signature'],
          ),
          MenuProduct(
            id: 'prod-c2',
            tenantId: tenantId,
            categoryId: 'cat-coffee-1',
            name: 'Cappuccino',
            description: 'Classic Italian espresso with frothed milk',
            price: 4.99,
            imageUrl: 'https://placehold.co/200x200/795548/FFFFFF?text=Cappuccino',
            isPopular: true,
          ),
          MenuProduct(
            id: 'prod-c3',
            tenantId: tenantId,
            categoryId: 'cat-coffee-1',
            name: 'Americano',
            description: 'Espresso diluted with hot water',
            price: 3.99,
            imageUrl: 'https://placehold.co/200x200/3E2723/FFFFFF?text=Americano',
          ),
          MenuProduct(
            id: 'prod-c4',
            tenantId: tenantId,
            categoryId: 'cat-coffee-1',
            name: 'Mocha',
            description: 'Espresso with chocolate and steamed milk',
            price: 5.99,
            imageUrl: 'https://placehold.co/200x200/5D4037/FFFFFF?text=Mocha',
            tags: ['Sweet'],
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-coffee-2',
        tenantId: tenantId,
        name: 'Cakes & Pastries',
        description: 'Freshly baked treats',
        sortOrder: 1,
        products: [
          MenuProduct(
            id: 'prod-p1',
            tenantId: tenantId,
            categoryId: 'cat-coffee-2',
            name: 'Chocolate Cake',
            description: 'Rich Belgian chocolate layer cake',
            price: 6.99,
            imageUrl: 'https://placehold.co/200x200/4E342E/FFFFFF?text=Chocolate',
            isPopular: true,
          ),
          MenuProduct(
            id: 'prod-p2',
            tenantId: tenantId,
            categoryId: 'cat-coffee-2',
            name: 'Cheesecake',
            description: 'New York style with berry compote',
            price: 7.49,
            imageUrl: 'https://placehold.co/200x200/FFF8E1/000000?text=Cheesecake',
          ),
          MenuProduct(
            id: 'prod-p3',
            tenantId: tenantId,
            categoryId: 'cat-coffee-2',
            name: 'Croissant',
            description: 'Buttery French pastry',
            price: 3.49,
            imageUrl: 'https://placehold.co/200x200/FFE0B2/000000?text=Croissant',
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-coffee-3',
        tenantId: tenantId,
        name: 'Cold Brews',
        description: 'Refreshing iced beverages',
        sortOrder: 2,
        products: [
          MenuProduct(
            id: 'prod-cb1',
            tenantId: tenantId,
            categoryId: 'cat-coffee-3',
            name: 'Iced Latte',
            description: 'Cold espresso with chilled milk over ice',
            price: 5.99,
            imageUrl: 'https://placehold.co/200x200/8D6E63/FFFFFF?text=Iced',
          ),
          MenuProduct(
            id: 'prod-cb2',
            tenantId: tenantId,
            categoryId: 'cat-coffee-3',
            name: 'Cold Brew',
            description: '12-hour steeped smooth cold coffee',
            price: 4.99,
            imageUrl: 'https://placehold.co/200x200/3E2723/FFFFFF?text=Cold+Brew',
            isPopular: true,
          ),
        ],
      ),
    ];
  }

  List<MenuCategory> _getSushiSpotMenu(String tenantId) {
    return [
      MenuCategory(
        id: 'cat-sushi-1',
        tenantId: tenantId,
        name: 'Nigiri',
        description: 'Hand-pressed sushi rice with fresh fish',
        sortOrder: 0,
        products: [
          MenuProduct(
            id: 'prod-n1',
            tenantId: tenantId,
            categoryId: 'cat-sushi-1',
            name: 'Salmon Nigiri (2pc)',
            description: 'Fresh Atlantic salmon over seasoned rice',
            price: 6.99,
            imageUrl: 'https://placehold.co/200x200/FF7043/FFFFFF?text=Salmon',
            isPopular: true,
          ),
          MenuProduct(
            id: 'prod-n2',
            tenantId: tenantId,
            categoryId: 'cat-sushi-1',
            name: 'Tuna Nigiri (2pc)',
            description: 'Premium bluefin tuna',
            price: 8.99,
            imageUrl: 'https://placehold.co/200x200/C62828/FFFFFF?text=Tuna',
            tags: ['Premium'],
          ),
          MenuProduct(
            id: 'prod-n3',
            tenantId: tenantId,
            categoryId: 'cat-sushi-1',
            name: 'Shrimp Nigiri (2pc)',
            description: 'Butterflied sweet shrimp',
            price: 5.99,
            imageUrl: 'https://placehold.co/200x200/FFAB91/000000?text=Shrimp',
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-sushi-2',
        tenantId: tenantId,
        name: 'Specialty Rolls',
        description: "Chef's creative signature rolls",
        sortOrder: 1,
        products: [
          MenuProduct(
            id: 'prod-r1',
            tenantId: tenantId,
            categoryId: 'cat-sushi-2',
            name: 'Dragon Roll',
            description: 'Eel, cucumber topped with avocado and unagi sauce',
            price: 16.99,
            imageUrl: 'https://placehold.co/200x200/1A237E/FFFFFF?text=Dragon',
            isPopular: true,
            tags: ['Signature'],
          ),
          MenuProduct(
            id: 'prod-r2',
            tenantId: tenantId,
            categoryId: 'cat-sushi-2',
            name: 'Rainbow Roll',
            description: 'California roll topped with assorted sashimi',
            price: 18.99,
            imageUrl: 'https://placehold.co/200x200/7B1FA2/FFFFFF?text=Rainbow',
            isPopular: true,
            tags: ['Colorful'],
          ),
          MenuProduct(
            id: 'prod-r3',
            tenantId: tenantId,
            categoryId: 'cat-sushi-2',
            name: 'Spicy Tuna Roll',
            description: 'Spicy tuna with cucumber and spicy mayo',
            price: 12.99,
            imageUrl: 'https://placehold.co/200x200/D32F2F/FFFFFF?text=Spicy',
            tags: ['Spicy'],
          ),
          MenuProduct(
            id: 'prod-r4',
            tenantId: tenantId,
            categoryId: 'cat-sushi-2',
            name: 'California Roll',
            description: 'Crab, avocado, cucumber - classic favorite',
            price: 10.99,
            imageUrl: 'https://placehold.co/200x200/4CAF50/FFFFFF?text=Cali',
          ),
        ],
      ),
      MenuCategory(
        id: 'cat-sushi-3',
        tenantId: tenantId,
        name: 'Beverages',
        description: 'Japanese drinks and more',
        sortOrder: 2,
        products: [
          MenuProduct(
            id: 'prod-b1',
            tenantId: tenantId,
            categoryId: 'cat-sushi-3',
            name: 'Green Tea',
            description: 'Traditional Japanese green tea',
            price: 2.49,
            imageUrl: 'https://placehold.co/200x200/81C784/000000?text=Green+Tea',
          ),
          MenuProduct(
            id: 'prod-b2',
            tenantId: tenantId,
            categoryId: 'cat-sushi-3',
            name: 'Ramune Soda',
            description: 'Japanese marble soda - Original flavor',
            price: 3.99,
            imageUrl: 'https://placehold.co/200x200/03A9F4/FFFFFF?text=Ramune',
          ),
        ],
      ),
    ];
  }
}
