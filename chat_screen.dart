import 'package:e_commerce_2/features/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class Message {
  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
  final String? imageUrl;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.imageUrl,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'] ?? '',
      senderId: map['sender_id'],
      createdAt: DateTime.parse(map['created_at']),
      imageUrl: map['image_url'] as String?,
    );
  }
}

// ------------------- Scroll Controller -------------------
final scrollController = ScrollController();

// ------------------- Delete Function -------------------
Future<void> deleteMessageForEveryone(
  SupabaseClient supabase,
  String messageId,
) async {
  await supabase.from('messages').delete().eq('id', messageId);
}

// ------------------- Messages Provider -------------------
final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final supabase = ref.read(supabaseProvider);

  final data = await supabase
      .from('messages')
      .select()
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true);

  return data.map<Message>((e) => Message.fromMap(e)).toList();
});

// ------------------- Chat Screen -------------------
class ChatScreen extends ConsumerWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final currentUser = ref.read(currentUserProvider)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0.5,
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser.id;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () async {
                          if (!isMe) return;

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete message?'),
                              content: const Text(
                                  'This will delete the message for everyone.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteMessageForEveryone(
                              ref.read(supabaseProvider),
                              msg.id,
                            );
                            ref.invalidate(
                                messagesProvider(conversationId));
                          }
                        },
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.72,
                          ),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 10),
                          padding: msg.imageUrl != null
                              ? const EdgeInsets.all(4)
                              : const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: msg.imageUrl != null &&
                                  msg.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(msg.imageUrl!),
                                )
                              : Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(conversationId: conversationId),
        ],
      ),
    );
  }
}

// ------------------- Message Input -------------------
class _MessageInput extends ConsumerStatefulWidget {
  final String conversationId;
  const _MessageInput({required this.conversationId});

  @override
  ConsumerState<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<_MessageInput> {
  final controller = TextEditingController();
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final supabase = ref.read(supabaseProvider);
    final currentUser = ref.read(currentUserProvider)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: () async {
              final XFile? file =
                  await picker.pickImage(source: ImageSource.gallery);
              if (file == null) return;

              final path =
                  'chat_images/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

              await supabase.storage.from('chat-bucket').uploadBinary(
                    path,
                    await file.readAsBytes(),
                  );

              final url =
                  supabase.storage.from('chat-bucket').getPublicUrl(path);

              await supabase.from('messages').insert({
                'conversation_id': widget.conversationId,
                'sender_id': currentUser.id,
                'content': '',
                'image_url': url,
              });

              await supabase.from('conversations').update({
                'last_message_at': DateTime.now().toIso8601String(),
              }).eq('id', widget.conversationId);

              ref.invalidate(messagesProvider(widget.conversationId));
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              controller.clear();

              await supabase.from('messages').insert({
                'conversation_id': widget.conversationId,
                'sender_id': currentUser.id,
                'content': text,
              });

              await supabase.from('conversations').update({
                'last_message_at': DateTime.now().toIso8601String(),
              }).eq('id', widget.conversationId);

              ref.invalidate(messagesProvider(widget.conversationId));
            },
          ),
        ],
      ),
    );
  }
}
