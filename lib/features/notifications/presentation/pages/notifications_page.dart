import 'package:flutter/material.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationLocalDatasource _datasource;
  late Future<List<NotificationEntity>> _future;

  @override
  void initState() {
    super.initState();
    _datasource = NotificationLocalDatasource(db: DatabaseHelper.instance);
    _future = _load();
  }

  Future<List<NotificationEntity>> _load() async {
    await _datasource.ensureTable();
    return _datasource.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<NotificationEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = notifications[index];
                final date = DateTime.tryParse(item.createdAt);
                final formatted = date == null
                    ? item.createdAt
                    : '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active,
                      color: Colors.deepPurple,
                    ),
                    title: Text(item.title),
                    subtitle: Text('${item.body}\n$formatted'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
