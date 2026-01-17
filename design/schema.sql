-- =============================================================================
-- QR-INFINITY: MULTI-TENANT DATABASE SCHEMA
-- PostgreSQL / Supabase Compatible
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. TENANTS TABLE (The Root of Multi-Tenancy)
-- Each restaurant/shop is a separate tenant
-- -----------------------------------------------------------------------------
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,          -- Subdomain: e.g., "joes-pizza" -> joes-pizza.qrinfinity.com
    custom_domain VARCHAR(255) UNIQUE,          -- Custom domain: e.g., "menu.joespizza.com"
    plan_tier VARCHAR(50) DEFAULT 'free',       -- free, pro, enterprise
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast subdomain/domain lookups (critical for routing)
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_custom_domain ON tenants(custom_domain);

-- -----------------------------------------------------------------------------
-- 2. PROFILES TABLE (Users linked to Tenants)
-- Links Supabase Auth users to tenant roles
-- -----------------------------------------------------------------------------
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'staff',  -- admin, staff
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for tenant-based queries
CREATE INDEX idx_profiles_tenant_id ON profiles(tenant_id);

-- -----------------------------------------------------------------------------
-- 3. THEME CONFIGS TABLE (Customization per Tenant)
-- Stores theming options: colors, fonts, border radius
-- One tenant can have multiple themes, only one active
-- -----------------------------------------------------------------------------
CREATE TABLE theme_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL DEFAULT 'Default',
    primary_color VARCHAR(7) NOT NULL DEFAULT '#FF5722',      -- HEX color
    secondary_color VARCHAR(7) DEFAULT '#FFC107',
    background_color VARCHAR(7) DEFAULT '#FFFFFF',
    text_color VARCHAR(7) DEFAULT '#212121',
    font_family VARCHAR(100) DEFAULT 'Roboto',                -- Google Fonts name
    border_radius_config JSONB DEFAULT '{"small": 4, "medium": 8, "large": 16}',
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraint: Only one active theme per tenant
    CONSTRAINT unique_active_theme_per_tenant 
        EXCLUDE USING btree (tenant_id WITH =) WHERE (is_active = TRUE)
);

CREATE INDEX idx_theme_configs_tenant_id ON theme_configs(tenant_id);
CREATE INDEX idx_theme_configs_active ON theme_configs(tenant_id) WHERE is_active = TRUE;

-- -----------------------------------------------------------------------------
-- 4. CATEGORIES TABLE (Product Grouping)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_tenant_id ON categories(tenant_id);
CREATE INDEX idx_categories_sort ON categories(tenant_id, sort_order);

-- -----------------------------------------------------------------------------
-- 5. PRODUCTS TABLE (Menu Items)
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_tenant_id ON products(tenant_id);
CREATE INDEX idx_products_category ON products(tenant_id, category_id);
CREATE INDEX idx_products_available ON products(tenant_id) WHERE is_available = TRUE;


-- =============================================================================
-- ROW LEVEL SECURITY (RLS) STRATEGY
-- =============================================================================
-- 
-- GOAL: Ensure Tenant A NEVER sees Tenant B's data.
-- 
-- STRATEGY: "Tenant Isolation via RLS Policies"
-- 
-- 1. ENABLE RLS on all tables (except `tenants` for public slug lookup)
-- 
-- 2. For AUTHENTICATED users (shop_admin, system_admin apps):
--    - Extract tenant_id from the user's JWT claims or profile lookup.
--    - Policy: SELECT/INSERT/UPDATE/DELETE WHERE tenant_id = auth.jwt()->>'tenant_id'
-- 
-- 3. For ANONYMOUS users (client_panel app - viewing menus):
--    - Allow SELECT on products, categories, theme_configs WHERE tenant matches
--      the requested subdomain/domain (passed as a request parameter).
--    - No INSERT/UPDATE/DELETE allowed.
-- 
-- 4. For SYSTEM ADMINS (our internal use):
--    - A special role 'service_role' bypasses RLS for administrative tasks.
-- 
-- =============================================================================

-- Enable RLS on all tenant-scoped tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE theme_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- PROFILES: Users can only see/edit their own profile within their tenant
-- -----------------------------------------------------------------------------
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- THEME_CONFIGS: Tenant admins can manage, anonymous can view active
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can manage tenant themes"
    ON theme_configs FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Anyone can view active themes"
    ON theme_configs FOR SELECT
    USING (is_active = TRUE);

-- -----------------------------------------------------------------------------
-- CATEGORIES: Tenant admins can manage, anyone can view visible
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can manage tenant categories"
    ON categories FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Anyone can view visible categories"
    ON categories FOR SELECT
    USING (is_visible = TRUE);

-- -----------------------------------------------------------------------------
-- PRODUCTS: Tenant admins can manage, anyone can view available
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can manage tenant products"
    ON products FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Anyone can view available products"
    ON products FOR SELECT
    USING (is_available = TRUE);

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
