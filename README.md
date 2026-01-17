# 🍽️ QR-Infinity

> Multi-tenant QR Menu SaaS Platform built with Flutter & Supabase

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📖 Overview

QR-Infinity is a **white-label QR menu solution** for restaurants, cafés, and food businesses. Each tenant (restaurant) gets their own customizable digital menu accessible via unique URLs.

### Key Features
- 🏪 **Multi-tenant architecture** - Single codebase serves unlimited restaurants
- 🎨 **Custom theming** - Each tenant can customize colors & fonts
- 📱 **PWA support** - Works on any device without app installation
- 🔐 **Role-based access** - Separate admin panels for shop owners and system admins
- ⚡ **Real-time updates** - Powered by Supabase

---

## 🏗️ Architecture

```
qr-menu/
├── apps/
│   ├── client_panel/     # Customer-facing menu PWA (port 3000)
│   ├── shop_admin/       # Shop owner dashboard (port 3001)
│   └── system_admin/     # Super admin panel (port 3002)
├── packages/
│   └── shared_core/      # Shared models, services, repositories
└── docs/
    └── database/         # SQL schemas
```

### The 3-App Strategy

| App | Purpose | Users |
|-----|---------|-------|
| **Client Panel** | Menu display for customers | End users (via QR code) |
| **Shop Admin** | Product & menu management | Restaurant owners |
| **System Admin** | Tenant management | Platform administrators |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x+)
- [Supabase Account](https://supabase.com) (free tier works)
- Chrome browser (for web development)

### 1. Clone & Install

```bash
git clone <repo-url>
cd qr-menu
flutter pub get
```

### 2. Setup Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the schema:
   ```
   docs/database/schema_v1.sql
   ```
3. Get your credentials from **Settings → API**

### 3. Configure Environment

Edit `packages/shared_core/lib/src/config/env.dart`:

```dart
class Env {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 4. Run the Apps

Open 3 terminals:

```bash
# Terminal 1: Client Panel (Customer Menu)
cd apps/client_panel
flutter run -d chrome --web-port=3000
# → http://localhost:3000/{tenant-slug}

# Terminal 2: Shop Admin (Restaurant Dashboard)
cd apps/shop_admin
flutter run -d chrome --web-port=3001
# → http://localhost:3001

# Terminal 3: System Admin (Platform Management)
cd apps/system_admin
flutter run -d chrome --web-port=3002
# → http://localhost:3002
```

---

## 📋 Quick Start Guide

### Create Your First Restaurant

1. Open **System Admin** at `http://localhost:3002`
2. Click **"Create New Tenant"**
3. Fill in:
   - Shop Name: `My Restaurant`
   - URL Slug: `my-restaurant`
   - Owner Email: `owner@example.com`
4. Click **Create Tenant**

### View the Menu

Open the **Client Panel** at:
```
http://localhost:3000/my-restaurant
```

### Add Products

Use the **Shop Admin** at `http://localhost:3001` to add menu items.

---

## 🧪 Demo Data

After setup, a demo tenant was created:

| Field | Value |
|-------|-------|
| Tenant Name | Demo Kebab House 3 |
| URL | `http://localhost:3000/demo-kebab-house-3` |

---

## 📁 Project Structure

```
packages/shared_core/
├── lib/src/
│   ├── config/env.dart           # Supabase credentials
│   ├── services/supabase_service.dart
│   ├── repositories/
│   │   ├── tenant_repository.dart
│   │   ├── product_repository.dart
│   │   └── auth_repository.dart
│   ├── models/
│   │   ├── tenant.dart
│   │   ├── product.dart
│   │   └── theme_config.dart
│   └── theme/theme_factory.dart
```

---

## 🛠️ Development Commands

```bash
# Analyze all packages
flutter analyze .

# Run tests
flutter test

# Build for production
cd apps/client_panel
flutter build web --release

# Clean build artifacts
flutter clean
```

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

Built with ❤️ using **Flutter** & **Supabase**
