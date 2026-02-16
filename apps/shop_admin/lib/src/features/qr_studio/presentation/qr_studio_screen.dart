/// QR Studio Screen — Menu QR + Wi-Fi QR Tabs
///
/// Tab 1: Menu QR with shop URL
/// Tab 2: Wi-Fi QR with SSID/Password/Encryption inputs
/// Both tabs support foreground color customization via HexColorPicker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../../navigation/admin_menu_drawer.dart';
import '../../auth/application/auth_provider.dart';

class QrStudioScreen extends ConsumerStatefulWidget {
  const QrStudioScreen({super.key});

  @override
  ConsumerState<QrStudioScreen> createState() => _QrStudioScreenState();
}

class _QrStudioScreenState extends ConsumerState<QrStudioScreen> {
  Color _qrColor = Colors.black;

  // Wi-Fi fields
  late TextEditingController _ssidController;
  late TextEditingController _passwordController;
  String _encryption = 'WPA';

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _prefillWifi(dynamic tenant) {
    if (_ssidController.text.isEmpty && tenant.wifiName != null) {
      _ssidController.text = tenant.wifiName!;
    }
    if (_passwordController.text.isEmpty && tenant.wifiPassword != null) {
      _passwordController.text = tenant.wifiPassword!;
    }
  }

  String _buildWifiQrData() {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();
    final enc = _encryption == 'None' ? 'nopass' : _encryption;
    return 'WIFI:T:$enc;S:$ssid;P:$password;;';
  }

  InputDecoration _inputDecoration({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);
    if (tenant != null) _prefillWifi(tenant);

    final menuQrData = tenant != null
        ? 'https://menu.app/${tenant.slug}'
        : 'https://menu.app/demo';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('QR Stüdyosu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Menü QR'),
              Tab(icon: Icon(Icons.wifi), text: 'Wi-Fi QR'),
            ],
          ),
        ),
        endDrawer: const AdminMenuDrawer(),
        body: TabBarView(
          children: [
            // ═══ TAB 1: Menu QR ═══
            _buildMenuTab(menuQrData, tenant),

            // ═══ TAB 2: Wi-Fi QR ═══
            _buildWifiTab(tenant),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(String qrData, dynamic tenant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _QrCard(
            qrData: qrData,
            qrColor: _qrColor,
            title: tenant?.name ?? 'Mekan İsmi',
            subtitle: 'Dijital Menü',
          ),
          const SizedBox(height: 32),

          // Color picker
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: HexColorPicker(
              label: 'QR Ön Plan Rengi',
              color: _qrColor,
              onColorChanged: (c) => setState(() => _qrColor = c),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildWifiTab(dynamic tenant) {
    final wifiData = _buildWifiQrData();
    final hasData = _ssidController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Wi-Fi Inputs
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wi-Fi Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ssidController,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _inputDecoration(label: 'Ağ Adı (SSID)', icon: Icons.wifi),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _inputDecoration(label: 'Şifre', icon: Icons.lock_outline),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _encryption,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration(label: 'Şifreleme Türü', icon: Icons.security),
                  items: const [
                    DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2')),
                    DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                    DropdownMenuItem(value: 'None', child: Text('Şifresiz')),
                  ],
                  onChanged: (v) => setState(() => _encryption = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Preview
          if (hasData) ...[
            _QrCard(
              qrData: wifiData,
              qrColor: _qrColor,
              title: _ssidController.text.trim(),
              subtitle: 'Wi-Fi Bağlantı QR',
            ),
            const SizedBox(height: 24),
          ] else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('SSID girin, QR oluşturulsun', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),

          // Color Picker
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: HexColorPicker(
              label: 'QR Ön Plan Rengi',
              color: _qrColor,
              onColorChanged: (c) => setState(() => _qrColor = c),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share),
          label: const Text('Paylaş'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: const Text('İndir (PNG)'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ─── QR Card Widget ───

class _QrCard extends StatelessWidget {
  final String qrData;
  final Color qrColor;
  final String title;
  final String subtitle;

  const _QrCard({
    required this.qrData,
    required this.qrColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220.0,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: qrColor),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: qrColor),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}
