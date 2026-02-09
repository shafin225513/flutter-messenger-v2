import 'package:e_commerce_2/features/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:e_commerce_2/features/chat_screen.dart';

// Provider to fetch all users (contacts) + their conversation info
final chatSearchProvider = StateProvider<String>((ref) => '');

final contactsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final allProfiles = await supabase
      .from('profiles')
      .select('id, username')
      .neq('id', currentUser.id);

  final convos = await supabase
      .from('conversations')
      .select()
      .or('user1.eq.${currentUser.id},user2.eq.${currentUser.id}')
      .order('last_message_at', ascending: false, nullsFirst: false);

  final Map<String, Map<String, dynamic>> convosMap = {};
  for (var c in convos) {
    final otherId = c['user1'] == currentUser.id ? c['user2'] : c['user1'];
    convosMap[otherId] = {
      'conversation_id': c['id'],
      'last_message_at': c['last_message_at'] as String?,
    };
  }

  final merged = allProfiles.map((p) {
    final convo = convosMap[p['id']];
    return {
      'other_user_id': p['id'],
      'username': (p['username'] as String?) ?? 'Unknown',
      'conversation_id': convo?['conversation_id'],
      'last_message_at': convo?['last_message_at'],
    };
  }).toList();

  merged.sort((a, b) {
    final aTime = a['last_message_at'] as String?;
    final bTime = b['last_message_at'] as String?;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  });

  return merged;
});

// Utility to get or create conversation
Future<String> getOrCreateConversation({
  required SupabaseClient supabase,
  required String currentUserId,
  required String otherUserId,
}) async {
  final user1 = currentUserId.compareTo(otherUserId) < 0
      ? currentUserId
      : otherUserId;
  final user2 = currentUserId.compareTo(otherUserId) < 0
      ? otherUserId
      : currentUserId;

  final existing = await supabase
      .from('conversations')
      .select()
      .eq('user1', user1)
      .eq('user2', user2)
      .maybeSingle();

  if (existing != null) return existing['id'] as String;

  final created = await supabase
      .from('conversations')
      .insert({'user1': user1, 'user2': user2})
      .select()
      .single();

  return created['id'] as String;
}

class ContactListScreen extends ConsumerWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final supabase = ref.read(supabaseProvider);
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.lightBlueAccent,
  toolbarHeight: 110, // important
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Messenger',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            icon: Icon(Icons.search, size: 20),
          ),
          onChanged: (value) {
            ref.read(chatSearchProvider.notifier).state = value;
          },
        ),
      ),
    ],
  ),
),

      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          final query = ref.watch(chatSearchProvider).toLowerCase();
          final filteredChats = contacts.where((chat) {
            final username =
                (chat['username'] as String?)?.toLowerCase() ?? '';
            return username.contains(query);
          }).toList();

          if (filteredChats.isEmpty) {
            return const Center(child: Text('No matching chats'));
          }

          return ListView.separated(
            itemCount: filteredChats.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              final contact = contacts[index];
              final username = chat['username'] as String;
              final lastMsg = contact['last_message_at'] as String?;

              return InkWell(
                onTap: () async {
                  if (currentUser == null) return;

                  final conversationId = contact['conversation_id'] != null
                      ? contact['conversation_id'] as String
                      : await getOrCreateConversation(
                          supabase: supabase,
                          currentUserId: currentUser.id,
                          otherUserId:
                              contact['other_user_id'] as String,
                        );

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(conversationId: conversationId),
                    ),
                  );

                  ref.invalidate(contactsProvider);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMsg ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
