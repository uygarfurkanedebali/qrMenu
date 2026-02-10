-- =====================================================
-- RPC FUNCTION: check_shop_access
-- =====================================================
-- Purpose: Check if the authenticated user has access to a shop
-- Used by: Shop Admin login flow
-- Returns: BOOLEAN (true if user is owner OR admin)
-- =====================================================

CREATE OR REPLACE FUNCTION public.check_shop_access(shop_slug TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant_id UUID;
  v_owner_email TEXT;
  v_user_email TEXT;
  v_user_role TEXT;
BEGIN
  -- Get current user's email and role
  SELECT email INTO v_user_email
  FROM auth.users
  WHERE id = auth.uid();

  IF v_user_email IS NULL THEN
    RETURN FALSE; -- Not authenticated
  END IF;

  -- Get user's role from profiles
  SELECT role INTO v_user_role
  FROM public.profiles
  WHERE id = auth.uid();

  -- Admins have access to everything
  IF v_user_role = 'admin' THEN
    RETURN TRUE;
  END IF;

  -- Check if shop exists and get owner email
  SELECT id, owner_email INTO v_tenant_id, v_owner_email
  FROM public.tenants
  WHERE slug = shop_slug;

  IF v_tenant_id IS NULL THEN
    RETURN FALSE; -- Shop doesn't exist
  END IF;

  -- Check if current user is the owner
  IF v_owner_email = v_user_email THEN
    RETURN TRUE;
  END IF;

  -- Default: no access
  RETURN FALSE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.check_shop_access(TEXT) TO authenticated;

-- Comment
COMMENT ON FUNCTION public.check_shop_access(TEXT) IS 
'Checks if the authenticated user has access to a shop. Returns true if user is the owner or an admin.';
