import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/bloc/event_bloc.dart';

// ── Organizer Dashboard ─────────────────────────────────────────────────────
class OrganizerDashboardPage extends StatefulWidget {
  const OrganizerDashboardPage({super.key});
  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<EventBloc>().add(EventLoadByOrganizer(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = [
          _OrganizerEventsTab(organizerId: authState.user.id),
          const QrScanTab(),
          const ProfileTab(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.event),
                label: 'My Events',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan QR',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class _OrganizerEventsTab extends StatelessWidget {
  final String organizerId;
  const _OrganizerEventsTab({required this.organizerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/create-event');
              if (!context.mounted) return;
              context.read<EventBloc>().add(EventLoadByOrganizer(organizerId));
            },
          ),
        ],
      ),
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state is EventCreated ||
              state is EventUpdated ||
              state is EventDeleted) {
            context.read<EventBloc>().add(EventLoadByOrganizer(organizerId));
          }
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No events created yet'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/create-event');
                        if (!context.mounted) return;
                        context.read<EventBloc>().add(
                          EventLoadByOrganizer(organizerId),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.events.length,
              itemBuilder: (_, i) => _OrganizerEventCard(
                event: state.events[i],
                organizerId: organizerId,
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _OrganizerEventCard extends StatelessWidget {
  final EventEntity event;
  final String organizerId;

  const _OrganizerEventCard({required this.event, required this.organizerId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(event.location, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await context.push(
                      '/organizer/event-view',
                      extra: {'event': event, 'organizerId': organizerId},
                    );
                    if (!context.mounted) return;
                    context.read<EventBloc>().add(
                      EventLoadByOrganizer(organizerId),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await context.push(
                      '/organizer/event-update',
                      extra: {'event': event, 'organizerId': organizerId},
                    );
                    if (!context.mounted) return;
                    context.read<EventBloc>().add(
                      EventLoadByOrganizer(organizerId),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final confirmed =
                        await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text(
                              'Are you sure you want to delete this event?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (!confirmed || !context.mounted) return;

                    context.read<EventBloc>().add(EventDelete(event.id));
                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );
                    if (!context.mounted) return;
                    context.read<EventBloc>().add(
                      EventLoadByOrganizer(organizerId),
                    );
                  },
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QrScanTab extends StatelessWidget {
  const QrScanTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validate Tickets'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan attendee tickets',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/scan'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Scanner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Profile Tab ──────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _updateSubmitted = false;

  Future<void> _showUpdateProfileDialog() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final nameCtrl = TextEditingController(text: auth.user.name);
    final emailCtrl = TextEditingController(text: auth.user.email);
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Password (optional)',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _updateSubmitted = true;
    });
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        userId: auth.user.id,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim().isEmpty
            ? null
            : passwordCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_updateSubmitted && state is AuthAuthenticated) {
          _updateSubmitted = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (_updateSubmitted && state is AuthError) {
          _updateSubmitted = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _showUpdateProfileDialog,
                icon: const Icon(Icons.edit),
                tooltip: 'Update Profile',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  onTap: () => context.push('/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Update Profile'),
                  onTap: _showUpdateProfileDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
