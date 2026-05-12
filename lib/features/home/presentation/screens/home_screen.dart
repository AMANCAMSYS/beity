import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.home,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بيتي',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                'الملف الشخصي',
                textDirection: TextDirection.rtl,
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text(
                'قوائم المشتريات',
                textDirection: TextDirection.rtl,
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to shopping lists
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: const Text(
                'الدعوات',
                textDirection: TextDirection.rtl,
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/invitations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text(
                'إدارة الأعضاء',
                textDirection: TextDirection.rtl,
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to manage members
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل تسجيل الخروج: ${e.toString()}',
                          textDirection: TextDirection.rtl,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'مرحباً بك في بيتي',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Text(
              'تطبيق إدارة المنزل والمشتريات',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to shopping lists
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text(
                'قوائم المشتريات',
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
