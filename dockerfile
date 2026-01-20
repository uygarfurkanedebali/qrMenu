# Stage 1: Build Flutter Web Apps
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy all files (including packages and apps)
COPY . .

# Build System Admin
WORKDIR /app/apps/system_admin
RUN flutter pub get
RUN flutter build web --release

# Build Shop Admin
WORKDIR /app/apps/shop_admin
RUN flutter pub get
RUN flutter build web --release

# Build Client Panel
WORKDIR /app/apps/client_panel
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Python
FROM python:3.10-slim

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Python server file
COPY main.py .

# Copy build artifacts from builder stage
# We deliberately maintain the directory structure expected by main.py variables:
# SYSTEM_ADMIN_BUILD = ... 'apps', 'system_admin', 'build', 'web'

# Create necessary directories
RUN mkdir -p apps/system_admin/build/web \
    && mkdir -p apps/shop_admin/build/web \
    && mkdir -p apps/client_panel/build/web

# Copy files
COPY --from=builder /app/apps/system_admin/build/web ./apps/system_admin/build/web
COPY --from=builder /app/apps/shop_admin/build/web ./apps/shop_admin/build/web
COPY --from=builder /app/apps/client_panel/build/web ./apps/client_panel/build/web

EXPOSE 80

CMD ["python", "main.py", "--port", "80"]