import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_page.dart';

final supabase = Supabase.instance.client;

class EmergencyScreen extends StatefulWidget {
  final String adminEmail;
  final String userId;
  const EmergencyScreen({required this.adminEmail, required this.userId, super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Map<String, dynamic>> emergencies = [];
  late StreamSubscription<List<Map<String, dynamic>>> emergencySubscription;

  @override
  void initState() {
    super.initState();
    _fetchExistingEmergencies();

    final emergencyStream =
        supabase.from('emergencies').stream(primaryKey: ['id']);
    emergencySubscription = emergencyStream.listen((data) {
      setState(() {
        emergencies = data
          ..sort((a, b) =>
              (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      });
    });
  }

  Future<void> _fetchExistingEmergencies() async {
    final response = await supabase
        .from('emergencies')
        .select('*')
        .order('created_at', ascending: false);

    setState(() {
      emergencies = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _updateAlertStatus(dynamic id, String newStatus) async {
    await supabase.from('emergencies').update({'status': newStatus}).eq('id', id);
  }

  // ADDED: robust Maps opener with fallbacks
  Future<void> _openMaps(double lat, double lng) async {
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng(Incident)');
  final nav = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  final web = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

  if (await canLaunchUrl(geo)) {
    await launchUrl(geo, mode: LaunchMode.externalApplication);
    return;
  }
  if (await canLaunchUrl(nav)) {
    await launchUrl(nav, mode: LaunchMode.externalApplication);
    return;
  }
  // Force external app (Chrome) for https
  if (await canLaunchUrl(web)) {
    final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
    if (ok) return;
  }
  // Last resort: open inside the app’s custom tab/webview
  await launchUrl(web, mode: LaunchMode.inAppBrowserView);

if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Google Maps!')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default: // 'new'
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    emergencySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HeartEase'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text("Admin",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(widget.adminEmail,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      const Divider(height: 32),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout', style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          final navigator = Navigator.of(context); // capture before await
                          await supabase.auth.signOut();
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Added Settings gear button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: emergencies.isEmpty
          ? const Center(child: Text("No active emergencies"))
          : ListView.builder(
              itemCount: emergencies.length,
              itemBuilder: (context, index) {
                final emergency = emergencies[index];
                final id = emergency['id'];
                final location = emergency['location'] ?? 'Unknown';
                final coordinates = emergency['coordinates'] ?? 'Unknown';
                final time = emergency['time']?.toString() ?? 'Unknown';
                final address = emergency['address'] ?? 'Unknown';
                final status = (emergency['status'] ?? 'new').toString();

                double? latitude, longitude;
                if (coordinates.contains(',')) {
                  final parts = coordinates.split(',');
                  if (parts.length == 2) {
                    latitude = double.tryParse(parts[0].trim());
                    longitude = double.tryParse(parts[1].trim());
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🚨 Emergency Alert 🚨',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(status.toUpperCase()),
                              backgroundColor: _getStatusColor(status),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoRow('Location:', location),
                        _infoRow('Coordinates:', coordinates),
                        _infoRow('Time:', time),
                        _infoRow('Full Address:', address),
                        const SizedBox(height: 18),
                        if (status == 'new') ...[
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: latitude != null && longitude != null
                                    ? () async {
                                        await _updateAlertStatus(id, 'accepted');
                                        if (!mounted) return;
                                        await _openMaps(latitude!, longitude!);
                                      }
                                    : null,
                                child: const Text('Accept & Navigate'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  await _updateAlertStatus(id, 'dismissed');
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Alert dismissed')),
                                  );
                                },
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ),
                        ] else if (status == 'accepted') ...[
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () async {
                                  await _updateAlertStatus(id, 'completed');
                                },
                                child: const Text('Mark as Completed'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(' $value')),
          ],
        ),
      );
}
