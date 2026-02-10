-- ============================================================
-- FIX PERMISSIONS SQL SCRIPT
-- Run in Supabase SQL Editor
-- ============================================================

-- ╔════════════════════════════════════════════════════════════╗
-- ║  PART 1: STORAGE — 'products' BUCKET                     ║
-- ╚════════════════════════════════════════════════════════════╝

-- Create the 'products' storage bucket (public for viewing)
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Policy: Anyone can VIEW product images (public menu)
CREATE POLICY "Public can view product images"
ON storage.objects FOR SELECT
USING (bucket_id = 'products');

-- Policy: Authenticated users can UPLOAD product images
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'products');

-- Policy: Authenticated users can UPDATE product images
CREATE POLICY "Authenticated users can update product images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'products')
WITH CHECK (bucket_id = 'products');

-- Policy: Authenticated users can DELETE product images
CREATE POLICY "Authenticated users can delete product images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'products');


-- ╔════════════════════════════════════════════════════════════╗
-- ║  PART 2: ORDERS TABLE — RLS POLICIES                     ║
-- ╚════════════════════════════════════════════════════════════╝

-- Create orders table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id),
  table_number TEXT,
  customer_name TEXT,
  customer_note TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create order_items table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ── Orders Policies ──

-- Anyone (anon customer) can INSERT orders  
-- (they just scanned a QR code and placed an order)
CREATE POLICY "Anyone can create orders"
ON public.orders FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Shop owners can VIEW their own orders
CREATE POLICY "Owners can view their orders"
ON public.orders FOR SELECT
TO authenticated
USING (
  tenant_id IN (
    SELECT id FROM public.tenants WHERE owner_email = auth.email()
  )
);

-- Shop owners can UPDATE their own orders (change status)
CREATE POLICY "Owners can update their orders"
ON public.orders FOR UPDATE
TO authenticated
USING (
  tenant_id IN (
    SELECT id FROM public.tenants WHERE owner_email = auth.email()
  )
)
WITH CHECK (
  tenant_id IN (
    SELECT id FROM public.tenants WHERE owner_email = auth.email()
  )
);

-- ── Order Items Policies ──

-- Anyone can INSERT order items (part of placing an order)
CREATE POLICY "Anyone can create order items"
ON public.order_items FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Shop owners can VIEW order items for their orders
CREATE POLICY "Owners can view their order items"
ON public.order_items FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM public.orders o 
    JOIN public.tenants t ON o.tenant_id = t.id 
    WHERE t.owner_email = auth.email()
  )
);

-- Customers can also view their own order items (by order_id)
-- (Anonymous read of specific order items for order confirmation)
CREATE POLICY "Anon can view order items by order_id"
ON public.order_items FOR SELECT
TO anon
USING (true);

COMMENT ON TABLE public.orders IS 'Customer orders placed via QR menu';
COMMENT ON TABLE public.order_items IS 'Individual items within an order';
