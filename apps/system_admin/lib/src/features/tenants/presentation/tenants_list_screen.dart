/// Tenants List Screen — UPGRADED VERSION
/// 
/// Features:
/// - Displays all created tenants from the database
/// - Dynamic URL generation (works on any domain)
/// - Delete functionality with confirmation
/// - Tenant details dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantsListScreen extends StatefulWidget {
  const TenantsListScreen({super.key});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  List<Tenant>? _tenants;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await SupabaseService.client
          .from('tenants')
          .select()
          .order('created_at', ascending: false);

      final tenants = (response as List)
          .map((json) => Tenant.fromJson(json))
          .toList();

      setState(() {
        _tenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTenant(Tenant tenant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('⚠️ Delete Tenant', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${tenant.name}"?\n\n'
          'This will permanently delete:\n'
          '• The shop\n'
          '• All products\n'
          '• All orders\n'
          '• All related data\n\n'
          'This action CANNOT be undone!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.client
          .from('tenants')
          .delete()
          .eq('id', tenant.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deleted "${tenant.name}"'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadTenants(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTenantDetails(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => _TenantDetailsDialog(tenant: tenant),
    );
  }

  String _getShopAdminUrl(String slug) {
    // Use current domain instead of hardcoded localhost
    final origin = Uri.base.origin;
    return '$origin/$slug/shopadmin';
  }

  String _getClientMenuUrl(String slug) {
    final origin = Uri.base.origin;
    return '$origin/$slug/menu';
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.store, size: 24),
            SizedBox(width: 8),
            Text('All Tenants'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTenants,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading tenants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTenants,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tenants == null || _tenants!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No tenants created yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tenant to get started',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenants!.length,
      itemBuilder: (context, index) {
        final tenant = _tenants![index];
        return _TenantCard(
          tenant: tenant,
          onTap: () => _showTenantDetails(tenant),
          onDelete: () => _deleteTenant(tenant),
          onOpenShopAdmin: () => _openUrl(_getShopAdminUrl(tenant.slug)),
          onOpenClientMenu: () => _openUrl(_getClientMenuUrl(tenant.slug)),
          onCopySlug: () => _copyText(tenant.slug),
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onOpenShopAdmin;
  final VoidCallback onOpenClientMenu;
  final VoidCallback onCopySlug;

  const _TenantCard({
    required this.tenant,
    required this.onTap,
    required this.onDelete,
    required this.onOpenShopAdmin,
    required this.onOpenClientMenu,
    required this.onCopySlug,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: Color(0xFF6366F1), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tenant.slug,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Color(0xFF60A5FA),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                              onPressed: onCopySlug,
                              tooltip: 'Copy slug',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    onPressed: onDelete,
                    tooltip: 'Delete tenant',
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFF334155)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenShopAdmin,
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      label: const Text('Shop Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF60A5FA),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenClientMenu,
                      icon: const Icon(Icons.restaurant_menu, size: 16),
                      label: const Text('Client Menu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF60A5FA),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDate(tenant.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _TenantDetailsDialog extends StatelessWidget {
  final Tenant tenant;

  const _TenantDetailsDialog({required this.tenant});

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tenant.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFF334155)),
            
            _DetailRow(
              label: 'Tenant ID',
              value: tenant.id,
              onCopy: () => _copyText(context, tenant.id),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Slug',
              value: tenant.slug,
              onCopy: () => _copyText(context, tenant.slug),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Owner Email',
              value: tenant.ownerEmail ?? 'N/A',
              onCopy: tenant.ownerEmail != null 
                  ? () => _copyText(context, tenant.ownerEmail!) 
                  : null,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Status',
              value: tenant.isActive ? '✅ Active' : '❌ Inactive',
              valueColor: tenant.isActive ? Colors.green.shade400 : Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Created',
              value: '${tenant.createdAt.day}/${tenant.createdAt.month}/${tenant.createdAt.year} at ${tenant.createdAt.hour}:${tenant.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Last Updated',
              value: '${tenant.updatedAt.day}/${tenant.updatedAt.month}/${tenant.updatedAt.year}',
            ),
            
            const SizedBox(height: 24),
            const Text(
              '🔗 Quick Links',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _LinkChip(
                  label: 'Shop Admin',
                  url: '${Uri.base.origin}/${tenant.slug}/shopadmin',
                ),
                _LinkChip(
                  label: 'Client Menu',
                  url: '${Uri.base.origin}/${tenant.slug}/menu',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontFamily: label == 'Tenant ID' || label == 'Slug' ? 'monospace' : null,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Copy',
          ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  final String label;
  final String url;

  const _LinkChip({required this.label, required this.url});

  void _openUrl() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openUrl,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 14, color: Color(0xFF60A5FA)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
