# Python'un hafif bir sürümünü baz alıyoruz
FROM python:3.10-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Gereksinimleri kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Tüm proje dosyalarını kopyala
COPY . .

# Uygulamanın çalışacağı portu belirt (Örn: Flask/FastAPI genelde 5000 veya 8000 kullanır)
EXPOSE 8000

# Uygulamayı başlat (Örnek: app.py çalıştırılıyor)
CMD ["python", "main.py", "--port", "80"]