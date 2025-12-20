
import 'package:flutter/material.dart';
import 'package:flutter_application/models/channel_preview.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/chat_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/chat_service.dart';
import 'package:flutter_application/services/socket_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:intl/intl.dart';

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChannelPreview> _allChannels = [];
  bool _isLoading = true;
  String _currentRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _currentRole = AppUser().role;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    SocketService.onEvent('refresh_chat', (data) {
        _loadData(); 
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = AppUser().id;
    if (userId != null) {
      final data = await ChatService.getUserChannels();
      if (mounted) {
        setState(() {
          _allChannels = data;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    if (AppUser().role != _currentRole) {
       _currentRole = AppUser().role;
       _loadData(); // Re-fetch or re-filter
    }

    // Filter based on Role and Type
    List<ChannelPreview> listTab1 = [];
    List<ChannelPreview> listTab2 = [];
    String titleTab1 = "";
    String titleTab2 = "";
    String emptyTab1 = "";
    String emptyTab2 = "";

    if (_currentRole == 'owner') {
      // Owner Mode
      // Tab 1: Queries received 
      listTab1 = _allChannels.where((c) => c.myRole == 'owner' && c.type == 'query').toList();
      titleTab1 = "Enquiries";
      emptyTab1 = "No new enquiries.";

      // Tab 2: My Properties/Tenants 
      listTab2 = _allChannels.where((c) => c.myRole == 'owner' && c.type == 'lease').toList();
      titleTab2 = "Tenants";
      emptyTab2 = "No active tenant chats.";
    } else {
      // Tenant Mode
      // Tab 1: My Queries sent 
      listTab1 = _allChannels.where((c) => c.myRole == 'tenant' && c.type == 'query').toList();
      titleTab1 = "My Queries";
      emptyTab1 = "You haven't sent any enquiries.";

      // Tab 2: My Rentals/Owners 
      listTab2 = _allChannels.where((c) => c.myRole == 'tenant' && c.type == 'lease').toList();
      titleTab2 = "Owners";
      emptyTab2 = "No active owner chats.";
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: titleTab1),
            Tab(text: titleTab2),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChatList(listTab1, emptyTab1),
              _buildChatList(listTab2, emptyTab2),
            ],
          ),
    );
  }

  Widget _buildChatList(List<ChannelPreview> channels, String emptyMsg) {
    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 82), 
      itemBuilder: (context, index) {
        return _buildChatTile(channels[index]);
      },
    );
  }

  Widget _buildChatTile(ChannelPreview chat) {
    String timeStr = "";
    if (chat.lastMessageTime != null) {
      final now = DateTime.now();
      final diff = now.difference(chat.lastMessageTime!);
      if (diff.inDays == 0) {
        timeStr = DateFormat('HH:mm').format(chat.lastMessageTime!);
      } else if (diff.inDays < 7) {
        timeStr = DateFormat('EEE').format(chat.lastMessageTime!);
      } else {
        timeStr = DateFormat('dd/MM').format(chat.lastMessageTime!);
      }
    }

    final isLease = chat.type == 'lease';
    final isImage = chat.lastMessageType == 'image';

    return Material(
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          
          final tenantIdParam = chat.myRole == 'owner' ? chat.otherUserId : AppUser().id!;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                propertyId: chat.propertyId,
                tenantId: tenantIdParam,
                channelType: isLease ? 'lease' : 'query',
              ),
            ),
          );
          _loadData(); 
        },
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: (chat.otherUserProfile != null) 
                  ? NetworkImage(ApiService.buildImageUrl(chat.otherUserProfile!)) 
                  : null,
              child: (chat.otherUserProfile == null) 
                  ? const Icon(Icons.person, color: Colors.grey) 
                  : null,
            ),
            if (chat.propertyImage != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    image: DecorationImage(
                      image: NetworkImage(ApiService.buildImageUrl(chat.propertyImage!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                chat.otherUserName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (isLease)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[200]!)
                    ),
                    child: const Text("LEASE", style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                Expanded(
                  child: Text(
                    chat.propertyTitle,
                    style: const TextStyle(
                      fontSize: 12, 
                      color: AppTheme.primaryColor, 
                      fontWeight: FontWeight.w600
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (isImage) 
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.image, size: 14, color: Colors.grey),
                  ),
                Expanded(
                  child: Text(
                    isImage ? "Sent a photo" : chat.lastMessage,
                    style: TextStyle(
                      color: chat.lastMessage.isEmpty ? Colors.grey[400] : Colors.grey[700], 
                      fontSize: 14,
                      fontStyle: chat.lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
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
