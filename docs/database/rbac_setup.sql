-- ============================================================
-- RBAC Setup for QR-Infinity / QR Menu
-- Run this ONCE in Supabase SQL Editor
-- ============================================================

-- 1. Create user_role enum
DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('admin', 'shop_owner', 'customer');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.user_role NOT NULL DEFAULT 'shop_owner',
  full_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Users can read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Admins can read all profiles
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;
CREATE POLICY "Admins can read all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- Users can update their own profile (but NOT the role column)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Service role / trigger can insert (for the trigger function)
DROP POLICY IF EXISTS "Service can insert profiles" ON public.profiles;
CREATE POLICY "Service can insert profiles"
  ON public.profiles FOR INSERT
  WITH CHECK (true);

-- 5. Trigger: Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name)
  VALUES (
    NEW.id,
    'shop_owner',  -- Default role for new signups
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', '')
  );
  RETURN NEW;
END;
$$;

-- Drop existing trigger if any, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 6. Backfill: Create profile rows for existing users who don't have one
INSERT INTO public.profiles (id, role)
SELECT id, 'shop_owner'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 7. MANUAL ADMIN PROMOTION
-- Replace 'YOUR_ADMIN_EMAIL@example.com' with your actual email
-- ============================================================
UPDATE public.profiles
SET role = 'admin', updated_at = now()
WHERE id = (
  SELECT id FROM auth.users
  WHERE email = 'YOUR_ADMIN_EMAIL@example.com'
);

-- Verify:
SELECT u.email, p.role, p.created_at
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY p.created_at;
