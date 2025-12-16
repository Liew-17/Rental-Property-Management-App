import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/clickable_image.dart';
import 'package:flutter_application/models/channel.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/message.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/services/chat_service.dart';

class ChatRecordPage extends StatefulWidget {
  final int leaseId;

  const ChatRecordPage({
    super.key,
    required this.leaseId,
  });

  @override
  State<ChatRecordPage> createState() => _ChatRecordPageState();
}

class _ChatRecordPageState extends State<ChatRecordPage> {
  // Chat State
  Channel? _channel;
  List<Message> messages = [];
  bool _isLoadingChannel = true;
  
  // UI Controllers
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isLoadingMore = false;

  int get _currentUserId => AppUser().id!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final channel = await ChatService.getChannelByLease(widget.leaseId);

      if (channel != null) {
        setState(() {
          _channel = channel;
          _isLoadingChannel = false;
        });
      
        _loadInitialMessages();
      } else {
        if (mounted) {
          setState(() => _isLoadingChannel = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No chat history found for this lease.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error initializing chat: $e");
      if (mounted) setState(() => _isLoadingChannel = false);
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_channel == null) return;
    try {
      List<Message> fetchedMessages = await ChatService.getMessages(
        channelId: _channel!.id,
        limit: 20,
      );

      if (mounted) {
        setState(() => messages = fetchedMessages);
        _sortMessagesByTime(ascending: true);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Failed to load messages: $e");
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || messages.isEmpty || _channel == null) return;
    _isLoadingMore = true;

    int offset = messages.length;

    try {
      List<Message> olderMessages = await ChatService.getMessages(
        channelId: _channel!.id,
        limit: 10,
        offset: offset,
      );

      if (olderMessages.isNotEmpty) {
        final existingIds = messages.map((m) => m.id).toSet();
        olderMessages = olderMessages.where((m) => !existingIds.contains(m.id)).toList();

        if (olderMessages.isNotEmpty && _scrollController.hasClients) {
          double beforeOffset = _scrollController.position.pixels;

          setState(() => messages.insertAll(0, olderMessages));
          _sortMessagesByTime(ascending: true);

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

  void _sortMessagesByTime({bool ascending = true}) {
    messages.sort((a, b) =>
        ascending ? a.sentAt.compareTo(b.sentAt) : b.sentAt.compareTo(a.sentAt));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 50) _loadMoreMessages();

    final atBottom =
        _scrollController.offset >= _scrollController.position.maxScrollExtent - 20;
    setState(() => _showScrollToBottom = !atBottom);
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

  PreferredSizeWidget _buildAppBar() {
    if (_isLoadingChannel || _channel == null) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Chat History", style: TextStyle(color: Colors.black)),
      );
    }

    final bool isMeOwner = _currentUserId == _channel!.ownerId;
    
    final String displayName = isMeOwner ? _channel!.tenantName : _channel!.ownerName;
    final String? displayProfile = isMeOwner ? _channel!.tenantProfile : _channel!.ownerProfile;
    final String roleLabel = isMeOwner ? "Tenant" : "Landlord";
    final Color roleColor = isMeOwner ? Colors.blue : Colors.orange;
    
    final String propTitle = _channel!.displayTitle; 

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: const BackButton(color: Colors.black),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: (displayProfile != null && displayProfile.isNotEmpty)
                ? NetworkImage(ApiService.buildImageUrl(displayProfile))
                : null,
            child: (displayProfile == null || displayProfile.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.black, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: roleColor.withOpacity(0.5))
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  propTitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Message Builders (Same as original) ---
  Widget _buildMessage(Message msg) {
    bool isMe = msg.senderId == _currentUserId;

    switch (msg.type) {
      case "text":
        return _buildTextBubble(msg, isMe);
      case "image":
        return _buildImageBubble(msg, isMe);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(Message msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Text(
              msg.messageBody,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              "${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(Message msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey[200],
              child: ClickableImage(
                imageUrl: ApiService.buildImageUrl(msg.messageBody),
                fileName: "shared_image_${msg.id}",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              "${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingChannel) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_channel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Could not connect to chat history.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildMessage(messages[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToBottom
          ? SizedBox(
              height: 40,
              width: 40,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: _scrollToBottom,
                child: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
              ),
            )
          : null,
    );
  }
}