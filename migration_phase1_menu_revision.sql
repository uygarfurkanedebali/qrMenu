-- Phase 1: Menu & Branding Revision Migration

-- 1. Tenant: Add Banner URL
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS banner_url text;

-- 2. Categories: Update Schema
-- Check if table exists, if not create it
CREATE TABLE IF NOT EXISTS categories (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  image_url text, -- New Column
  sort_order integer DEFAULT 0, -- New Column
  is_visible boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ensure columns exist if table already existed
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='image_url') THEN
    ALTER TABLE categories ADD COLUMN image_url text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='sort_order') THEN
    ALTER TABLE categories ADD COLUMN sort_order integer DEFAULT 0;
  END IF;
END $$;

-- 3. Many-to-Many: Product Categories
CREATE TABLE IF NOT EXISTS product_categories (
  product_id uuid REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE NOT NULL,
  PRIMARY KEY (product_id, category_id)
);

-- 4. RLS Policies

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

-- CATEGORIES POLICIES
-- Public Read (Menu View)
CREATE POLICY "Public categories are viewable by everyone" 
ON categories FOR SELECT 
USING (true);

-- Admin Full Access (Shop Admin)
CREATE POLICY "Shop owners can manage their own categories" 
ON categories FOR ALL 
USING (
  auth.uid() IN (
    SELECT id FROM profiles 
    WHERE role = 'shop_owner'
  )
  AND 
  tenant_id IN (
    SELECT id FROM tenants 
    WHERE owner_email = auth.jwt() ->> 'email'
  )
);

-- PRODUCT_CATEGORIES POLICIES
-- Public Read
CREATE POLICY "Public product categories are viewable by everyone" 
ON product_categories FOR SELECT 
USING (true);

-- Admin Full Access
CREATE POLICY "Shop owners can manage product categories" 
ON product_categories FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM products p
    JOIN tenants t ON p.tenant_id = t.id
    WHERE p.id = product_categories.product_id
    AND t.owner_email = auth.jwt() ->> 'email'
  )
);
