import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/gradient_background.dart';
import '../../constants/design_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<ReminderItem> _reminders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    setState(() {
      _reminders.addAll([
        ReminderItem(
          id: '1',
          title: 'Morning meditation',
          description: 'Start your day with 10 minutes of meditation',
          priority: Priority.high,
          dueDate: DateTime.now().add(const Duration(hours: 2)),
          isCompleted: false,
          isFlagged: true,
        ),
        ReminderItem(
          id: '2',
          title: 'Energy check-in',
          description: 'Check how your energy feels throughout the day',
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          isCompleted: false,
          isFlagged: false,
        ),
        ReminderItem(
          id: '3',
          title: 'Gratitude practice',
          description: 'Write down three things you\'re grateful for',
          priority: Priority.low,
          dueDate: null,
          isCompleted: true,
          isFlagged: false,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reminders),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.clam),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.clam),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.clam),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_searchQuery.isNotEmpty) _buildSearchBar(),
              Expanded(child: _buildRemindersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(DesignConstants.paddingLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(DesignConstants.cornerRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search reminders...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Icon(Icons.clear, color: AppColors.textSecondary),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildRemindersList() {
    final filteredReminders = _reminders.where((reminder) {
      if (_searchQuery.isEmpty) return true;
      return reminder.title.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          reminder.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    if (filteredReminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: DesignConstants.paddingLarge),
            Text(
              'No reminders found',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignConstants.paddingLarge),
      itemCount: filteredReminders.length,
      itemBuilder: (context, index) {
        final reminder = filteredReminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(ReminderItem reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignConstants.padding),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignConstants.cornerRadiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getPriorityColor(reminder.priority).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              DesignConstants.cornerRadiusMedium,
            ),
          ),
          child: Icon(
            reminder.isCompleted ? Icons.check_circle : Icons.notifications,
            color: _getPriorityColor(reminder.priority),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reminder.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: reminder.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (reminder.isFlagged)
              const Icon(Icons.flag, color: AppColors.warning, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (reminder.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(reminder.dueDate!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(reminder.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(reminder.dueDate!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reminder.priority != Priority.low)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    reminder.priority,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityText(reminder.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(reminder.priority),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleReminderAction(value, reminder),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'toggle',
                  child: Text('Toggle Complete'),
                ),
                PopupMenuItem(
                  value: 'flag',
                  child: Text(reminder.isFlagged ? 'Unflag' : 'Flag'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () => _toggleReminderCompletion(reminder),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppStrings.priorityLow;
      case Priority.medium:
        return AppStrings.priorityMedium;
      case Priority.high:
        return AppStrings.priorityHigh;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return AppColors.error; // Overdue
    } else if (difference == 0) {
      return AppColors.warning; // Today
    } else if (difference <= 3) {
      return AppColors.warning; // Soon
    } else {
      return AppColors.textSecondary; // Normal
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '$difference days';
    }
  }

  void _toggleReminderCompletion(ReminderItem reminder) {
    setState(() {
      reminder.isCompleted = !reminder.isCompleted;
    });
  }

  void _handleReminderAction(String action, ReminderItem reminder) {
    switch (action) {
      case 'toggle':
        _toggleReminderCompletion(reminder);
        break;
      case 'flag':
        setState(() {
          reminder.isFlagged = !reminder.isFlagged;
        });
        break;
      case 'edit':
        _showEditReminderDialog(reminder);
        break;
      case 'delete':
        _showDeleteConfirmation(reminder);
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Reminders'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    // TODO: Implement add reminder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add reminder functionality coming soon!'),
        backgroundColor: AppColors.friendly,
      ),
    );
  }

  void _showEditReminderDialog(ReminderItem reminder) {
    // TODO: Implement edit reminder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit reminder functionality coming soon!'),
        backgroundColor: AppColors.friendly,
      ),
    );
  }

  void _showDeleteConfirmation(ReminderItem reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _reminders.remove(reminder);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ReminderItem {
  final String id;
  final String title;
  final String description;
  final Priority priority;
  final DateTime? dueDate;
  bool isCompleted;
  bool isFlagged;

  ReminderItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    this.isFlagged = false,
  });
}

enum Priority { low, medium, high }
