-- =============================================
-- QR-Infinity Database Schema v1.0
-- Multi-tenant QR Menu SaaS Platform
-- =============================================
-- Run this script in your Supabase SQL Editor
-- to set up the complete database schema.
-- =============================================

-- ===================
-- TENANTS TABLE
-- ===================
-- Represents shops/restaurants using the platform
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    owner_email TEXT,
    theme_config JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for slug lookups (main access pattern)
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON public.tenants(slug);

-- ===================
-- PRODUCTS TABLE
-- ===================
-- Menu items belonging to a tenant
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
    category_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for tenant lookups (main access pattern)
CREATE INDEX IF NOT EXISTS idx_products_tenant ON public.products(tenant_id);

-- ===================
-- CATEGORIES TABLE (Optional)
-- ===================
-- Product categories for organization
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_tenant ON public.categories(tenant_id);

-- ===================
-- ROW LEVEL SECURITY
-- ===================

-- Enable RLS on all tables
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- ===================
-- TENANT POLICIES
-- ===================

-- Public can view active tenants (for Client Panel)
CREATE POLICY "Public can view active tenants" 
    ON public.tenants 
    FOR SELECT 
    USING (is_active = true);

-- Allow insert for demo/testing (restrict in production)
CREATE POLICY "Allow insert tenants" 
    ON public.tenants 
    FOR INSERT 
    WITH CHECK (true);

-- Allow update for demo/testing
CREATE POLICY "Allow update tenants" 
    ON public.tenants 
    FOR UPDATE 
    USING (true);

-- ===================
-- PRODUCT POLICIES
-- ===================

-- Public can view available products for active tenants
CREATE POLICY "Public can view products" 
    ON public.products 
    FOR SELECT 
    USING (
        is_available = true 
        AND EXISTS (
            SELECT 1 FROM public.tenants 
            WHERE id = products.tenant_id 
            AND is_active = true
        )
    );

-- Allow insert for demo/testing
CREATE POLICY "Allow insert products" 
    ON public.products 
    FOR INSERT 
    WITH CHECK (true);

-- Allow update for demo/testing
CREATE POLICY "Allow update products" 
    ON public.products 
    FOR UPDATE 
    USING (true);

-- Allow delete for demo/testing
CREATE POLICY "Allow delete products" 
    ON public.products 
    FOR DELETE 
    USING (true);

-- ===================
-- CATEGORY POLICIES
-- ===================

-- Public can view categories
CREATE POLICY "Public can view categories" 
    ON public.categories 
    FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.tenants 
            WHERE id = categories.tenant_id 
            AND is_active = true
        )
    );

-- Allow all operations for demo
CREATE POLICY "Allow all category operations" 
    ON public.categories 
    FOR ALL 
    USING (true);

-- ===================
-- HELPER FUNCTIONS
-- ===================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
DROP TRIGGER IF EXISTS update_tenants_updated_at ON public.tenants;
CREATE TRIGGER update_tenants_updated_at
    BEFORE UPDATE ON public.tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SCHEMA SETUP COMPLETE
-- =============================================
