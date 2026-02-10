/// Create Tenant Screen
/// 
/// Form for System Admin to create new tenants (shops).
/// AUTOMATICALLY creates both auth user AND tenant record via RPC.
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_core/shared_core.dart';

class CreateTenantScreen extends StatefulWidget {
  const CreateTenantScreen({super.key});

  @override
  State<CreateTenantScreen> createState() => _CreateTenantScreenState();
}

class _CreateTenantScreenState extends State<CreateTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  Map<String, dynamic>? _successData;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  Future<void> _createTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successData = null;
    });

    try {
      if (!Env.isConfigured) {
        throw Exception('Supabase not configured.');
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final shopName = _nameController.text.trim();
      final slug = _slugController.text.trim();

      // Call RPC function that creates BOTH auth user and tenant
      final response = await SupabaseService.client.rpc(
        'create_shop_with_owner',
        params: {
          'p_shop_name': shopName,
          'p_slug': slug,
          'p_owner_email': email,
          'p_owner_password': password,
        },
      );

      // Parse response (it returns JSONB)
      final result = response as Map<String, dynamic>;
      
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create shop');
      }

      // Success!
      if (mounted) {
        setState(() {
          _successData = {
            'shopName': shopName,
            'slug': slug,
            'email': email,
            'password': password,
            'clientUrl': AppConfig.getClientMenuUrl(slug),
            'adminUrl': AppConfig.getShopAdminUrl(slug),
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$shopName" created with auth user!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      if (errorMessage.contains('function') && errorMessage.contains('does not exist')) {
        errorMessage = 'RPC function not found. Run: docs/database/create_shop_owner_function.sql';
      }
      
      setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!'), duration: Duration(milliseconds: 500)),
    );
  }

  /// Open URL in new browser tab
  void _openInNewTab(String url) {
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Shop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _successData != null ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    final d = _successData!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B), // Dark green for success
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF047857), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                '🎉 Shop & Auth User Created!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),

          _infoRow('Shop', d['shopName']),
          _infoRow('Slug', d['slug']),
          _infoRow('Email', d['email']),
          _infoRow('Password', d['password']),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔗 Links (click to open in new tab):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                _linkRow('Shop Admin', d['adminUrl']),
                _linkRow('Client Menu', d['clientUrl']),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Ready to Login!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Auth user was created automatically. Go to Shop Admin and login!',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => setState(() {
              _successData = null;
              _nameController.clear();
              _slugController.clear();
              _emailController.clear();
              _passwordController.clear();
            }),
            icon: const Icon(Icons.add_business),
            label: const Text('Create Another'),
          ),
        ],
      ),
    );
  }

  /// Clickable link row that opens URL in new tab
  Widget _linkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label: ',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _openInNewTab(url),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF60A5FA), // Light blue for links
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
            onPressed: () => _openInNewTab(url),
            tooltip: 'Open in new tab',
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () => _copy(url),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () => _copy(value),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          Text('Create a New Shop', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('This creates BOTH the shop AND the login account automatically.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Shop Name', hintText: 'e.g., Antigravity Burger',
              prefixIcon: Icon(Icons.store), border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            onChanged: (v) => _slugController.text = _generateSlug(v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _slugController,
            decoration: InputDecoration(
              labelText: 'URL Slug', hintText: 'e.g., antigravity-burger',
              prefixIcon: const Icon(Icons.link), border: const OutlineInputBorder(),
              helperText: 'Menu URL: ${AppConfig.clientPanelBaseUrl}/[slug]',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) return 'Only lowercase, numbers, hyphens';
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Owner Account', style: Theme.of(context).textTheme.labelLarge),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Owner Email', hintText: 'e.g., test@antigravity.com',
              prefixIcon: Icon(Icons.email), border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Owner Password', hintText: 'Min 6 characters',
              prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _isLoading ? null : _createTenant,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch),
            label: Text(_isLoading ? 'Creating...' : 'Create Shop & Account'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }
}
