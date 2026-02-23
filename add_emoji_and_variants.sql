-- EMOJI VE VARYANTLAR İÇİN SÜTUN EKLEME (Supabase)
-- Bu scripti SQL Editor üzerinde çalıştırabilirsiniz.

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS emoji text,
ADD COLUMN IF NOT EXISTS variants jsonb DEFAULT '[]'::jsonb;

-- Yorumlar:
-- emoji: Ürün isminin yanında gösterilecek emoji (Örn: 🍔)
-- variants: Ürünün gramaj/boyut gibi alt varyantları ve fiyatları. (Örn: [{"name": "130 gr", "price": 45.0}])
