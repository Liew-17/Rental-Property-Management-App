import 'package:flutter/material.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/my_request_page.dart'; 
import 'package:flutter_application/pages/my_favourite_page.dart'; 
import 'package:flutter_application/services/api_service.dart'; // Import ApiService
import 'package:flutter_application/services/user_service.dart'; // Import UserService
import 'package:flutter_application/theme.dart';
import 'package:image_picker/image_picker.dart'; // Import ImagePicker

class ProfilePage extends StatefulWidget {
  final VoidCallback? onRoleChanged;

  const ProfilePage({super.key, this.onRoleChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() => _isUploading = true);

        final success = await UserService.uploadProfilePic(pickedFile);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile picture updated!")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to upload image.")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _toggleRole(Set<String> newSelection) {
    setState(() {
      AppUser().role = newSelection.first;
    });

    widget.onRoleChanged?.call(); 
    

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Switched to ${AppUser().role} mode"),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppUser();
    final isOwner = user.role == 'owner';
    final safePadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60), // Increased top spacing for header
                _buildProfileHeader(user),
                const SizedBox(height: 30),
                
                // Menu Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Only show My Requests if NOT owner (Tenant Mode)
                      if (!isOwner) ...[
                        _buildMenuItem(
                          context,
                          icon: Icons.list_alt_rounded,
                          title: 'My Requests',
                          subtitle: 'View status of your rental applications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyRequestPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                      ],
                      
                      _buildMenuItem(
                        context,
                        icon: Icons.favorite_rounded,
                        title: 'My Favorites',
                        subtitle: 'Properties you have saved',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyFavouritePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Floating Role Switcher (Top Right)
          Positioned(
            top: safePadding + 16,
            right: 20,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(30),
              child:SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'tenant',
                  label: Text('Tenant'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: 'owner',
                  label: Text('Owner'),
                  icon: Icon(Icons.home_work_outlined),
                ),
              ],
              selected: {user.role},
              onSelectionChanged: _toggleRole,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor.withOpacity(0.2);
                    }
                    return Colors.white;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return Colors.grey;
                  },
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {

    return Column(
      children: [
        // Profile Image Section
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: (0.1)),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty)             
                      ? NetworkImage(
                          ApiService.buildImageUrl(user.profilePicUrl!),
                        )
                      : null,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : (user.profilePicUrl == null ||user.profilePicUrl!.isEmpty)?
                          const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          )
                        : null,

                ),
            ),
            // Camera Icon Button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        Text(
          user.name??"h",
          style: AppTheme.heading1.copyWith(fontSize: 24, color: Colors.black87),
        ),
        const SizedBox(height: 5),

        Text(
          user.email ?? 'user@example.com',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),

        // Location Badge
        if (user.city != null || user.state != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  [user.city, user.state].where((e) => e != null).join(', '),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}