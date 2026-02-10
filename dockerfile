# =====================================================
# OPTIMIZED DOCKERFILE FOR CI/CD
# =====================================================
# This Dockerfile expects pre-built Flutter web artifacts
# to exist in apps/*/build/web directories.
# The Flutter builds are done in parallel in GitHub Actions.
# =====================================================

# Use lightweight Python base image
FROM python:3.10-slim

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Python server file
COPY main.py .

# Create directory structure for build artifacts
# The GitHub Actions workflow will have already placed the builds here
RUN mkdir -p apps/system_admin/build/web \
    && mkdir -p apps/shop_admin/build/web \
    && mkdir -p apps/client_panel/build/web \
    && mkdir -p apps/landing_page/build/web

# Copy pre-built Flutter web artifacts
# These are created by parallel build jobs in GitHub Actions
COPY apps/system_admin/build/web ./apps/system_admin/build/web
COPY apps/shop_admin/build/web ./apps/shop_admin/build/web
COPY apps/client_panel/build/web ./apps/client_panel/build/web
COPY apps/landing_page/build/web ./apps/landing_page/build/web

# Expose port
EXPOSE 80

# Start Python server
CMD ["python", "main.py", "--port", "80"]

# =====================================================
# OPTIMIZATION NOTES:
# =====================================================
# - Removed Flutter builder stage (builds happen in CI)
# - Single-stage build = faster Docker build time
# - Smaller final image (~200MB vs ~1.5GB)
# - Leverages GitHub Actions caching for Flutter dependencies
# - Parallel builds in CI = 3-4x faster than sequential Docker builds
# =====================================================