import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../models/notification.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeTab = 'All'; // All, Pipeline, Insights, Actions, System

  List<AppNotification> _filterNotifications(List<AppNotification> items) {
    if (_activeTab == 'All') return items;
    
    // Custom mapping for categories
    return items.where((element) {
      final itemCat = element.displayCategory.toLowerCase();
      if (_activeTab == 'Pipeline') return itemCat == 'pipeline';
      if (_activeTab == 'Insights') return itemCat == 'insight';
      if (_activeTab == 'Actions') return itemCat == 'action';
      if (_activeTab == 'System') return itemCat == 'system' || itemCat == 'draft';
      return true;
    }).toList();
  }

  void _showDraftDialog(BuildContext context, AppNotification notif) {
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colors.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.mark_as_unread, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI AUTONOMOUS DRAFT',
                style: AppTheme.headingMd(context, colors.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TO: ${notif.displayDraftRecipient}',
                  style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'SUBJECT: ${notif.displayDraftSubject}',
                  style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  notif.displayDraftBody,
                  style: AppTheme.bodySm(context, colors.textSecondary).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ToastService.showSuccess(context, 'Draft copied to clipboard.');
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSuccess,
                foregroundColor: Colors.black,
              ),
              child: const Text('COPY TEXT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);
    final filteredItems = _filterNotifications(apiState.notifications);
    
    // Separate drafted communications
    final drafts = apiState.notifications.where((e) => e.displayCategory == 'draft').toList();

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'NOTIFICATIONS',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          TextButton(
            onPressed: () {
              apiState.markAllNotificationsAsRead();
              ToastService.showInfo(context, 'All notifications marked as read.');
            },
            child: Text(
              'MARK ALL READ',
              style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Filter Tabs
              _buildFilterTabs(context),
              const SizedBox(height: 20),

              // Section: Notification List
              Text(
                'SYSTEM ALERTS',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              if (filteredItems.isEmpty)
                _buildEmptyState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildNotificationRow(context, item);
                  },
                ),
              const SizedBox(height: 28),

              // Section: Drafted communications
              if (drafts.isNotEmpty) ...[
                Text(
                  'AUTONOMOUS COMM DRAFTS',
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                ...drafts.map((d) => _buildDraftCard(context, d)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final colors = AppTheme.of(context);
    final tabs = ['All', 'Pipeline', 'Insights', 'Actions', 'System'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSel = _activeTab == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(t),
              selected: isSel,
              selectedColor: colors.bgElevated,
              backgroundColor: colors.bgSurface,
              labelStyle: AppTheme.caption(context, isSel ? colors.accentPrimary : colors.textSecondary).copyWith(
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _activeTab = t;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationRow(BuildContext context, AppNotification item) {
    final colors = AppTheme.of(context);
    
    Color getCategoryColor() {
      switch (item.displayCategory) {
        case 'pipeline': return colors.accentPrimary;
        case 'insight': return colors.accentSecondary;
        case 'action': return colors.accentWarning;
        case 'draft': return colors.accentSuccess;
        case 'system':
        default:
          return colors.accentDanger;
      }
    }

    IconData getIcon() {
      switch (item.displayCategory) {
        case 'pipeline': return Icons.settings_input_component;
        case 'insight': return Icons.auto_graph;
        case 'action': return Icons.science_outlined;
        case 'draft': return Icons.mark_as_unread_outlined;
        case 'system':
        default:
          return Icons.warning_amber_outlined;
      }
    }

    return CustomCard(
      backgroundColor: item.displayIsRead ? colors.bgSurface : colors.bgSurface.withOpacity(0.9),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getCategoryColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(getIcon(), color: getCategoryColor(), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.displayCategory.toUpperCase(),
                      style: AppTheme.caption(context, getCategoryColor()).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('HH:mm').format(item.displayTimestamp),
                      style: AppTheme.monoSm(context, colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.displayTitle,
                  style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  item.displayBody,
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ],
            ),
          ),
          if (!item.displayIsRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: colors.accentPrimary, shape: BoxShape.circle),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, AppNotification draft) {
    final colors = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomCard(
        backgroundColor: colors.bgElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: colors.accentSuccess, size: 16),
                const SizedBox(width: 8),
                Text(
                  'TO: ${draft.displayDraftRecipient}',
                  style: AppTheme.caption(context, colors.accentSuccess).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              draft.displayDraftSubject,
              style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              draft.displayDraftBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption(context, colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _showDraftDialog(context, draft),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentSuccess,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  'VIEW FULL DRAFT',
                  style: AppTheme.caption(context, Colors.black).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined, color: colors.textSecondary.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "You're all caught up. New alerts will display here.",
            textAlign: TextAlign.center,
            style: AppTheme.caption(context, colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
