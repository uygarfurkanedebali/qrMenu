#!/usr/bin/env python3
"""
QR Menu - Production Server

Serves pre-built Flutter web applications as static files.
Dynamically injects correct base-href for slug-based apps.

URL Structure:
  /systemadmin/*       -> System Admin (apps/system_admin/build/web)
  /{slug}/shopadmin/*  -> Shop Admin (apps/shop_admin/build/web)  
  /{slug}/menu/*       -> Client Menu (apps/client_panel/build/web)
  /{slug}/*            -> Client Menu (default)
"""

import argparse
import os
import re
from flask import Flask, send_from_directory, redirect, Response, make_response

app = Flask(__name__)

# Build directories
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SYSTEM_ADMIN_BUILD = os.path.join(PROJECT_ROOT, 'apps', 'system_admin', 'build', 'web')
SHOP_ADMIN_BUILD = os.path.join(PROJECT_ROOT, 'apps', 'shop_admin', 'build', 'web')
CLIENT_PANEL_BUILD = os.path.join(PROJECT_ROOT, 'apps', 'client_panel', 'build', 'web')
LANDING_PAGE_BUILD = os.path.join(PROJECT_ROOT, 'apps', 'landing_page', 'build', 'web')

# Reserved paths that are not tenant slugs
RESERVED_PATHS = {'root', 'api', 'static', 'assets', 'favicon.ico', 'flutter_bootstrap.js', 'main.dart.js'}


def serve_flutter_app(build_dir, path='', base_href=None):
    """
    Serve files from a Flutter build directory.
    If base_href is provided and path is index.html, inject the correct base href.
    """
    if not os.path.exists(build_dir):
        return Response(
            f"<h1>Build Not Found</h1><p>Run: flutter build web --release</p>",
            status=500, content_type='text/html'
        )
    
    # If path is empty or a route (no file extension), serve index.html
    is_index = not path or '.' not in os.path.basename(path)
    if is_index:
        path = 'index.html'
    
    file_path = os.path.join(build_dir, path)
    
    # If file exists, serve it
    if os.path.exists(file_path):
        # If serving index.html with custom base_href, inject it
        if path == 'index.html' and base_href:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            # Replace base href (handles both "/" and other values)
            content = re.sub(
                r'<base\s+href="[^"]*"',
                f'<base href="{base_href}"',
                content
            )
            response = make_response(content)
            response.headers['Content-Type'] = 'text/html; charset=utf-8'
            return response
        return send_from_directory(build_dir, path)
    else:
        # For SPA routing, return index.html for unknown paths
        if base_href:
            index_path = os.path.join(build_dir, 'index.html')
            with open(index_path, 'r', encoding='utf-8') as f:
                content = f.read()
            content = re.sub(
                r'<base\s+href="[^"]*"',
                f'<base href="{base_href}"',
                content
            )
            response = make_response(content)
            response.headers['Content-Type'] = 'text/html; charset=utf-8'
            return response
        return send_from_directory(build_dir, 'index.html')


# ========================================
# SYSTEM ADMIN ROUTES (/root)
# ========================================

@app.route('/root')
@app.route('/root/')
def system_admin_index():
    return serve_flutter_app(SYSTEM_ADMIN_BUILD, base_href='/root/')


@app.route('/root/<path:path>')
def system_admin_files(path):
    return serve_flutter_app(SYSTEM_ADMIN_BUILD, path, base_href='/root/')


# ========================================
# SHOP ADMIN ROUTES
# ========================================

@app.route('/<slug>/shopadmin')
@app.route('/<slug>/shopadmin/')
def shop_admin_index(slug):
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
    base_href = f'/{slug}/shopadmin/'
    return serve_flutter_app(SHOP_ADMIN_BUILD, base_href=base_href)


@app.route('/<slug>/shopadmin/<path:path>')
def shop_admin_files(slug, path):
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
    base_href = f'/{slug}/shopadmin/'
    return serve_flutter_app(SHOP_ADMIN_BUILD, path, base_href=base_href)


# ========================================
# CLIENT MENU ROUTES
# ========================================

@app.route('/<slug>/menu')
@app.route('/<slug>/menu/')
def client_menu_index(slug):
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
    base_href = f'/{slug}/menu/'
    return serve_flutter_app(CLIENT_PANEL_BUILD, base_href=base_href)


@app.route('/<slug>/menu/<path:path>')
def client_menu_files(slug, path):
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
    base_href = f'/{slug}/menu/'
    return serve_flutter_app(CLIENT_PANEL_BUILD, path, base_href=base_href)


# ========================================
# FLUTTER WEB GLOBAL ASSETS
# ========================================

@app.route('/assets/<path:path>')
def serve_global_assets(path):
    # Assets are always served from the Client Panel build
    return serve_flutter_app(CLIENT_PANEL_BUILD, f'assets/{path}')


# ========================================
# ROOT (LANDING PAGE)
# ========================================

@app.route('/')
def root():
    return serve_flutter_app(CLIENT_PANEL_BUILD, base_href='/')

# ========================================
# CLIENT DEFAULT (/{slug}) & LANDING PAGE ASSETS
# ========================================

# Let's define:
# 1. Root / -> Landing Page (Served by Client Panel build)
# 2. Files for Landing Page (flutter_bootstrap.js, etc.) -> served if exist in CLIENT_PANEL_BUILD
# 3. Everything else -> Client Panel (Tenant)

@app.route('/<slug>')
@app.route('/<slug>/')
def client_default_or_landing_asset(slug):
    # Check if this slug is actually a file in client panel (root assets)
    path = slug
    file_path = os.path.join(CLIENT_PANEL_BUILD, path)
    if os.path.exists(file_path):
         return serve_flutter_app(CLIENT_PANEL_BUILD, path, base_href='/')
    
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
        
    # Tenant Slug
    base_href = f'/{slug}/'
    return serve_flutter_app(CLIENT_PANEL_BUILD, base_href=base_href)


@app.route('/<slug>/<path:path>')
def client_default_files(slug, path):
    if slug in RESERVED_PATHS:
        return Response("Not found", status=404)
    # Check if this is a file request or should be handled as SPA route
    if '.' in path.split('/')[-1]:
        # File request - check if it's an asset that might be requested from wrong base
        base_href = f'/{slug}/'
        return serve_flutter_app(CLIENT_PANEL_BUILD, path, base_href=base_href)
    # SPA route
    base_href = f'/{slug}/'
    return serve_flutter_app(CLIENT_PANEL_BUILD, base_href=base_href)


# ========================================
# ROOT
# ========================================




# ========================================
# MAIN
# ========================================

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='QR Menu Production Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=80, help='Port (default: 80)')
    parser.add_argument('--debug', action='store_true', help='Debug mode')
    
    args = parser.parse_args()
    
    # Check if builds exist
    print("\n📦 Checking builds...")
    builds_ok = True
    for name, path in [('System Admin', SYSTEM_ADMIN_BUILD), ('Shop Admin', SHOP_ADMIN_BUILD), ('Client Panel', CLIENT_PANEL_BUILD), ('Landing Page', LANDING_PAGE_BUILD)]:
        if os.path.exists(path):
            print(f"  ✅ {name}: {path}")
        else:
            print(f"  ❌ {name}: NOT FOUND")
            builds_ok = False
    
    if not builds_ok:
        print("\n⚠️  Some builds are missing. Run 'flutter build web --release' in each app folder.\n")
    
    print(f"""
╔══════════════════════════════════════════════════════════╗
║        QR MENU - PRODUCTION STATIC SERVER                ║
╠══════════════════════════════════════════════════════════╣
║  Server: http://{args.host}:{args.port}                           
║                                                          ║
║  Routes (with dynamic base-href injection):              ║
║    /root/*              → System Admin (RBAC)            ║
║    /{{slug}}/shopadmin/* → Shop Admin                     ║
║    /{{slug}}/menu/*      → Client Menu                    ║
║    /{{slug}}/*           → Client Menu                    ║
╚══════════════════════════════════════════════════════════╝
    """)
    
    app.run(host=args.host, port=args.port, debug=args.debug, threaded=True)
