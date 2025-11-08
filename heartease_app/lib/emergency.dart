import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_page.dart';

final supabase = Supabase.instance.client;
const String kTable = 'device_events';

class EmergencyScreen extends StatefulWidget {
  final String adminEmail;
  final String userId;
  const EmergencyScreen({
    required this.adminEmail,
    required this.userId,
    super.key,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Map<String, dynamic>> emergencies = [];
  StreamSubscription<List<Map<String, dynamic>>>? sub;

  @override
  void initState() {
    super.initState();
    _fetchOnce(); // initial load
    _watch(); // realtime updates
  }

  Future<void> _fetchOnce() async {
    try {
      final rows = await supabase
          .from(kTable)
          .select('*')
          .order('timestamp', ascending: false);
      setState(() => emergencies = List<Map<String, dynamic>>.from(rows));
      debugPrint('Loaded ${emergencies.length} rows from $kTable');
    } catch (e, st) {
      debugPrint('FETCH ERROR: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fetch error: $e')));
    }
  }

  void _watch() {
    try {
      final stream = supabase.from(kTable).stream(primaryKey: ['id']);
      sub = stream.listen((data) {
        data.sort(
          (a, b) => (b['timestamp'] ?? '').toString().compareTo(
            (a['timestamp'] ?? '').toString(),
          ),
        );
        setState(() => emergencies = data);
        debugPrint('Realtime received ${data.length} rows');
      });
    } catch (e, st) {
      debugPrint('STREAM ERROR: $e\n$st');
    }
  }

  Future<void> _updateAlertStatus(dynamic id, String newStatus) async {
    try {
      await supabase.from(kTable).update({'status': newStatus}).eq('id', id);
    } catch (e, st) {
      debugPrint('UPDATE ERROR: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update error: $e')));
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng(Incident)');
    final nav = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final web = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(nav)) {
      await launchUrl(nav, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(web)) {
      final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
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
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    sub?.cancel();
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
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.adminEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Divider(height: 32),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await supabase.auth.signOut();
                          nav.pushAndRemoveUntil(
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
        ],
      ),

      body: emergencies.isEmpty
          ? const Center(child: Text('No active emergencies'))
          : ListView.builder(
              itemCount: emergencies.length,
              itemBuilder: (context, i) {
                final e = emergencies[i];
                final id = e['id'];
                final status = (e['status'] ?? 'pending').toString();
                final time = e['timestamp']?.toString() ?? 'Unknown';
                final msg = e['message']?.toString() ?? '';
                final from = e['from_number']?.toString() ?? '';

                // parse lat/lon (numeric or text)
                final lat = (e['latitude'] is num)
                    ? (e['latitude'] as num).toDouble()
                    : double.tryParse('${e['latitude']}');
                final lon = (e['longitude'] is num)
                    ? (e['longitude'] as num).toDouble()
                    : double.tryParse('${e['longitude']}');

                final coordinates = (lat != null && lon != null)
                    ? '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'
                    : 'Unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                        _infoRow('From:', from),
                        _infoRow('Message:', msg),
                        _infoRow('Coordinates:', coordinates),
                        _infoRow('Time:', time),
                        const SizedBox(height: 18),

                        if (status == 'pending' || status == 'new') ...[
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: (lat != null && lon != null)
                                    ? () async {
                                        await _updateAlertStatus(
                                          id,
                                          'accepted',
                                        );
                                        if (!mounted) return;
                                        await _openMaps(lat, lon);
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
                                    const SnackBar(
                                      content: Text('Alert dismissed'),
                                    ),
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
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(' $value')),
      ],
    ),
  );
}
