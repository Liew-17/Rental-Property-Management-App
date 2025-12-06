import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/clickable_image.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application/models/message.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final int channelId;
  final int currentUserId;

  const ChatPage({super.key, required this.channelId, required this.currentUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  bool _showScrollToBottom = false;
  bool _isLoadingMore = false;

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void sortMessagesByTime({bool ascending = true}) {
    messages.sort((a, b) =>
        ascending ? a.sentAt.compareTo(b.sentAt) : b.sentAt.compareTo(a.sentAt));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels <= 50) {
      _loadMoreMessages();
    }

    final atBottom =
        _scrollController.offset >= _scrollController.position.maxScrollExtent - 20;
    setState(() {
      _showScrollToBottom = !atBottom;
    });
  }

  Future<void> _loadInitialMessages() async {
    try {
      List<Message> fetchedMessages = await ChatService.getMessages(
        channelId: widget.channelId,
        limit: 20,
      );

      setState(() => messages = fetchedMessages);
      sortMessagesByTime(ascending: true);

    } catch (e) {
      debugPrint("Failed to load messages: $e");
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || messages.isEmpty) return;
    _isLoadingMore = true;

    int offset = messages.length;

    try {
      List<Message> olderMessages = await ChatService.getMessages(
        channelId: widget.channelId,
        limit: 10,
        offset: offset,
      );

      if (olderMessages.isNotEmpty) {
        // Remove duplicates
        final existingIds = messages.map((m) => m.id).toSet();
        olderMessages = olderMessages.where((m) => !existingIds.contains(m.id)).toList();

        if (olderMessages.isNotEmpty && _scrollController.hasClients) {
          double beforeOffset = _scrollController.position.pixels;

          setState(() => messages.insertAll(0, olderMessages));
          sortMessagesByTime(ascending: true);

          // Wait for layout to update
          await Future.delayed(const Duration(milliseconds: 50));

          if (_scrollController.hasClients) {
            _scrollController.jumpTo(beforeOffset);
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to load older messages: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    try {
      Message msg = await ChatService.sendTextMessage(
        senderId: widget.currentUserId,
        channelId: widget.channelId,
        messageBody: text,
      );
      setState(() => messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      debugPrint("Failed to send text message: $e");
    }
  }

  Future<void> _sendImageMessage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      );

      if (pickedFile == null) return;

      final msg = await ChatService.sendImageMessage(
        senderId: widget.currentUserId,
        channelId: widget.channelId,
        imageFile: pickedFile,
      );

      setState(() => messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      debugPrint("Failed to send image: $e");
    }
  }

  Widget _buildMessage(Message msg) {
    bool isMe = msg.senderId == widget.currentUserId;

    switch (msg.type) {
      case "text":
        return _buildTextBubble(msg, isMe);
      case "image":
        return _buildImageBubble(msg, isMe);
      case "system":
        return _buildSystemMessage(msg);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(Message msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Text(
              msg.messageBody,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(Message msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        children: [
          ClickableImage(imageUrl: ApiService.buildImageUrl(msg.messageBody), fileName: "flutter_image"),
          const SizedBox(height: 4),
          Text(
            "${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(Message msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Text(
        msg.messageBody,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessage(messages[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sendImageMessage,
                      icon: const Icon(Icons.image),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                        ),
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendTextMessage,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 70,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToBottom,
                child: const Icon(Icons.arrow_downward),
              ),
            ),
        ],
      ),
    );
  }
}
