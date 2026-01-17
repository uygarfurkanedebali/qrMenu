-- =============================================
-- AUTOMATIC SHOP & AUTH USER CREATION
-- =============================================
-- Run this in Supabase SQL Editor
-- Creates both tenant record AND auth user in one call
-- =============================================

-- First, enable the pgcrypto extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.create_shop_with_owner(TEXT, TEXT, TEXT, TEXT);

-- Create the new function
CREATE OR REPLACE FUNCTION public.create_shop_with_owner(
    p_shop_name TEXT,
    p_slug TEXT,
    p_owner_email TEXT,
    p_owner_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id UUID;
    v_tenant_id UUID;
    v_encrypted_password TEXT;
BEGIN
    -- Validate inputs
    IF p_shop_name IS NULL OR p_shop_name = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Shop name is required');
    END IF;
    
    IF p_slug IS NULL OR p_slug = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Slug is required');
    END IF;
    
    IF p_owner_email IS NULL OR p_owner_email = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Owner email is required');
    END IF;
    
    IF p_owner_password IS NULL OR length(p_owner_password) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Password must be at least 6 characters');
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_owner_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists');
    END IF;
    
    -- Check if slug already exists
    IF EXISTS (SELECT 1 FROM public.tenants WHERE slug = p_slug) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Slug already exists');
    END IF;

    -- Generate UUIDs
    v_user_id := gen_random_uuid();
    v_tenant_id := gen_random_uuid();
    
    -- Encrypt password
    v_encrypted_password := crypt(p_owner_password, gen_salt('bf'));

    -- Create the auth user
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change
    )
    VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        p_owner_email,
        v_encrypted_password,
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        jsonb_build_object('shop_name', p_shop_name, 'tenant_id', v_tenant_id::text),
        FALSE,
        'authenticated',
        'authenticated',
        '',
        '',
        '',
        ''
    );

    -- Create the identity record
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        v_user_id,
        jsonb_build_object(
            'sub', v_user_id::text,
            'email', p_owner_email,
            'email_verified', true,
            'phone_verified', false
        ),
        'email',
        v_user_id::text,
        NOW(),
        NOW(),
        NOW()
    );

    -- Create the tenant record
    INSERT INTO public.tenants (
        id,
        name,
        slug,
        owner_email,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        v_tenant_id,
        p_shop_name,
        p_slug,
        p_owner_email,
        TRUE,
        NOW(),
        NOW()
    );

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'tenant_id', v_tenant_id,
        'shop_name', p_shop_name,
        'slug', p_slug,
        'email', p_owner_email,
        'message', 'Shop and owner created successfully'
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Email or slug already exists'
        );
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_shop_with_owner(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_shop_with_owner(TEXT, TEXT, TEXT, TEXT) TO anon;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

-- Test (optional - comment out after testing):
-- SELECT public.create_shop_with_owner('Test Shop', 'test-shop', 'test@example.com', 'password123');
