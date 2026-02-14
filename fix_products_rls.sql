-- ============================================================
-- PANIC FIX: DISABLE RLS ON PRODUCTS
-- Use this if all other RLS fixes fail with 42501.
-- This effectively makes the table public/unprotected.
-- ============================================================

ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'products';

-- (rowsecurity should be failing (false))
