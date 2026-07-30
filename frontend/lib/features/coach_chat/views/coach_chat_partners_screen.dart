import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/coach_chat_provider.dart';
import 'coach_chat_screen.dart';

class CoachChatPartnersScreen extends StatefulWidget {
  const CoachChatPartnersScreen({super.key});

  @override
  State<CoachChatPartnersScreen> createState() =>
      _CoachChatPartnersScreenState();
}

class _CoachChatPartnersScreenState extends State<CoachChatPartnersScreen> {
  bool _openedSinglePartner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPartners();
    });
  }

  Future<void> _loadPartners() async {
    final provider = context.read<CoachChatProvider>();
    await provider.loadPartners();
    if (!mounted || _openedSinglePartner || provider.partners.length != 1) {
      return;
    }

    _openedSinglePartner = true;
    final partner = provider.partners.single;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CoachChatScreen(
          partnerId: partner.partnerId,
          partnerName: partner.fullName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn PT – Gymer')),
      body: Consumer<CoachChatProvider>(
        builder: (context, provider, _) {
          if (provider.loadingPartners && provider.partners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.partners.isEmpty) {
            return Center(child: Text(provider.error!));
          }
          if (provider.partners.isEmpty) {
            return const Center(
              child: Text('Chưa có PT/Gymer nào đã kết nối để trò chuyện.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadPartners,
            child: ListView.separated(
              itemCount: provider.partners.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final partner = provider.partners[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      partner.fullName.isEmpty
                          ? '?'
                          : partner.fullName[0].toUpperCase(),
                    ),
                  ),
                  title: Text(partner.fullName),
                  subtitle: Text(
                    partner.lastMessage ?? 'Bắt đầu cuộc trò chuyện',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: partner.unreadCount > 0
                      ? Badge(label: Text('${partner.unreadCount}'))
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoachChatScreen(
                        partnerId: partner.partnerId,
                        partnerName: partner.fullName,
                      ),
                    ),
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
