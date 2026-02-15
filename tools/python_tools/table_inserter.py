import pandas as pd
import re
import time
from supabase import create_client, Client

# ==========================================
# ⚙️ AYARLAR (Buraları Mutlaka Doldur)
# ==========================================
CSV_FILE_PATH = r'C:\Users\admin\Desktop\Coding\qr_menu\tools\python_tools\HookInn_Lounge_Menu_Premium.csv' # İndirdiğin dosyanın tam yolu
SUPABASE_URL = "https://jswvvrxpjvsdqcayynzi.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impzd3Z2cnhwanZzZHFjYXl5bnppIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODA2OTQ2MSwiZXhwIjoyMDgzNjQ1NDYxfQ.UPzk_GqG0qbD1Pdm2T72vmXHrl8Fio_7TRiBE40g9f0"
TENANT_ID = "aabc6093-8b65-4c13-80e0-d30523ca9ffb" 
# ==========================================

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def main():
    print("📂 CSV Dosyası Okunuyor...")
    try:
        df = pd.read_csv(CSV_FILE_PATH)
    except FileNotFoundError:
        print("❌ HATA: CSV dosyası bulunamadı! Dosya yolunu kontrol et.")
        return

    print(f"📦 {len(df)} Ürün Yükleniyor...")
    
    # 1. KATEGORİLERİ OLUŞTUR
    unique_categories = df['Yeni_Kategori'].unique()
    cat_map = {}

    for idx, cat_name in enumerate(unique_categories):
        # Kategori var mı?
        res = supabase.table('categories').select('id').eq('tenant_id', TENANT_ID).eq('name', cat_name).execute()
        
        if res.data:
            cat_id = res.data[0]['id']
            print(f"  ℹ️ Kategori Mevcut: {cat_name}")
        else:
            print(f"  ➕ Yeni Kategori: {cat_name}")
            new_cat = supabase.table('categories').insert({
                "tenant_id": TENANT_ID, 
                "name": cat_name,
                "sort_order": (idx+1)*10
            }).execute()
            cat_id = new_cat.data[0]['id']
        
        cat_map[cat_name] = cat_id

    # 2. ÜRÜNLERİ EKLE
    for _, row in df.iterrows():
        try:
            name = row['Temizlenmiş_Urun_Adi']
            price = row['Fiyat']
            desc = row['Premium_Lounge_Aciklaması']
            img_url = row['Gorsel_Linki'] if pd.notna(row['Gorsel_Linki']) else None
            cat_id = cat_map[row['Yeni_Kategori']]
            
            # Ürün var mı?
            prod_res = supabase.table('products').select('id').eq('tenant_id', TENANT_ID).eq('name', name).execute()
            
            product_data = {
                "tenant_id": TENANT_ID,
                "category_id": cat_id,
                "name": name,
                "description": desc,
                "price": price,
                "image_url": img_url,
                "is_available": True
            }

            if prod_res.data:
                pid = prod_res.data[0]['id']
                supabase.table('products').update(product_data).eq('id', pid).execute()
                print(f"  ✏️ Güncellendi: {name}")
            else:
                supabase.table('products').insert(product_data).execute()
                print(f"  ✅ Eklendi: {name}")
                
            time.sleep(0.1) 

        except Exception as e:
            print(f"  ❌ HATA: {e}")

    print("🏁 Yükleme Tamamlandı!")

if __name__ == "__main__":
    main()