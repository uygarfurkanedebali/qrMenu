-- Add design_config column to tenants table
ALTER TABLE public.tenants
ADD COLUMN design_config JSONB DEFAULT '{}'::jsonb;
