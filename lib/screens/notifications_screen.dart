import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Your certificate is ready",
      message: "You've completed the course 'Advanced Flutter Development'",
      time: "2 hours ago",
      isRead: false,
      type: NotificationType.achievement,
    ),
    NotificationItem(
      title: "New course available",
      message: "Check out our latest course on Web Development",
      time: "Yesterday",
      isRead: true,
      type: NotificationType.course,
    ),
    NotificationItem(
      title: "Special offer",
      message: "30% discount on all premium courses for the next 48 hours",
      time: "2 days ago",
      isRead: true,
      type: NotificationType.promotion,
    ),
    NotificationItem(
      title: "Account update",
      message: "Your profile information has been updated successfully",
      time: "1 week ago",
      isRead: true,
      type: NotificationType.account,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF6366F1)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
              },
              child: Text(
                'Mark all as read',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(_notifications[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something new arrives',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    Color backgroundColor = notification.isRead 
        ? Colors.white 
        : const Color(0xFF6366F1).withOpacity(0.05);
    
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.achievement:
        iconData = Icons.emoji_events_outlined;
        iconColor = Colors.amber;
        break;
      case NotificationType.course:
        iconData = Icons.school_outlined;
        iconColor = const Color(0xFF6366F1);
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        iconColor = Colors.green;
        break;
      case NotificationType.account:
        iconData = Icons.person_outline;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
          // Handle notification tap
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.time,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NotificationType {
  achievement,
  course,
  promotion,
  account,
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
} 