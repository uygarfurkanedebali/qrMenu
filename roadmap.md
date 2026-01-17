# PROJECT ROADMAP: QR-INFINITY

## Phase 1: The Foundation (Current)
- [x] **Initialize Workspace:** Setup Melos for Monorepo management.
- [x] **App Scaffolding:** Create empty Flutter apps:
    - `apps/client_panel` (PWA for Customers)
    - `apps/shop_admin` (Dashboard for Shop Owners)
    - `apps/system_admin` (Super Admin for Us)
- [x] **Shared Core:** Create `packages/shared_core` for reusable logic (Models, API, Theme).
- [x] **DevOps:** Setup basic `analysis_options.yaml` and `.gitignore`.

## Phase 2: The Core Engine
- [x] **Database Schema:** Design Tenants, Products, Categories, Menus, Orders tables.
- [x] **Theme Engine:** Implement the JSON-to-Theme converter in `shared_core` (Critical for templates).
- [ ] **Auth:** Implement Multi-role Authentication (System Admin vs Shop Owner vs Anonymous Client).

## Phase 3: The Client Experience (Menu)
- [x] **Advanced Routing:** Implement Subdomain & Custom Domain parsing logic.
- [x] **Menu Renderer:** Build the UI that consumes the Theme Engine to display menus.
- [x] **Cart & Logic:** Local storage cart and ordering flow.

## Phase 4: The Shop Experience & Operations
- [x] **Setup:** Initialize `shop_admin` app with Riverpod & GoRouter.
- [x] **Dashboard:** Create responsive shell with Sidebar navigation.
- [ ] **Management Forms:** Product/Category CRUD operations.
- [ ] **QR Generator:** Generate and download QR codes for tables.inking to specific subdomains.
- [ ] **Payments:** Integration for Subscription (SaaS) and Ordering.
- [ ] **SEO & Optimization:** SSR considerations and Meta Tags for the Client Panel.