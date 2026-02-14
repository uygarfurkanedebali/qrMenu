-- CMS: Landing Page Configuration
-- Description: Singleton table to store dynamic content for the landing page.

-- 1. Create Table
CREATE TABLE IF NOT EXISTS public.landing_page_config (
    id int8 PRIMARY KEY DEFAULT 1, -- Singleton ID
    hero_title text NOT NULL DEFAULT 'Restoranınızın Dijital Geleceği',
    hero_description text NOT NULL DEFAULT 'QR-Infinity ile tanışın.',
    features_list jsonb DEFAULT '[]'::jsonb,
    contact_email text,
    is_maintenance_mode boolean DEFAULT false,
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT singleton_check CHECK (id = 1) -- Enforce singleton row
);

-- 2. Enable RLS
ALTER TABLE public.landing_page_config ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies

-- Public Read (Everyone can view the landing page)
CREATE POLICY "Public Read Access"
ON public.landing_page_config
FOR SELECT
USING (true);

-- System Admin Write (Only system admins can update)
-- Assuming 'system_admin' role exists in profiles or auth metadata. 
-- Adjust logic based on actual role implementation.
-- For now, using a placeholder check or existing 'service_role' for seed.
-- In production, link to profiles table role check:
-- USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'system_admin'))

CREATE POLICY "System Admin Update Access"
ON public.landing_page_config
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM profiles 
    WHERE role = 'system_admin'
  )
);

-- 4. Initial Seed (Upsert to ensure row 1 exists)
INSERT INTO public.landing_page_config (id, hero_title, hero_description, features_list, contact_email)
VALUES (
    1,
    'QR-Infinity ile Sınırları Kaldırın',
    'Henüz görsellerimiz yüklenmedi ama altyapımız hazır. Sistem yöneticisi panelinden bu metni değiştirebilirsiniz.',
    '[
        {"icon": "qr_code", "title": "Hızlı Erişim", "text": "Kamera ile anında menü."},
        {"icon": "analytics", "title": "Analitik", "text": "Müşteri davranışlarını izleyin."}
    ]'::jsonb,
    'contact@qrmenu.com'
)
ON CONFLICT (id) DO NOTHING;
