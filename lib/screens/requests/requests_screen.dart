import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/gradient_background.dart';
import '../../constants/design_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final List<RequestItem> _requests = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    setState(() {
      _requests.addAll([
        RequestItem(
          id: '1',
          title: 'Heal past trauma',
          description: 'Work on releasing childhood trauma',
          priority: Priority.high,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          isCompleted: false,
        ),
        RequestItem(
          id: '2',
          title: 'Forgive someone',
          description: 'Let go of resentment towards a family member',
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 14)),
          isCompleted: false,
        ),
        RequestItem(
          id: '3',
          title: 'Practice gratitude',
          description: 'Daily gratitude journaling',
          priority: Priority.low,
          dueDate: null,
          isCompleted: true,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.requests),
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
            onPressed: _showAddRequestDialog,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_searchQuery.isNotEmpty) _buildSearchBar(),
              Expanded(child: _buildRequestsList()),
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
          hintText: 'Search requests...',
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

  Widget _buildRequestsList() {
    final filteredRequests = _requests.where((request) {
      if (_searchQuery.isEmpty) return true;
      return request.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    if (filteredRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: DesignConstants.paddingLarge),
            Text(
              'No requests found',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignConstants.paddingLarge),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(RequestItem request) {
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
            color: _getPriorityColor(request.priority).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              DesignConstants.cornerRadiusMedium,
            ),
          ),
          child: Icon(
            request.isCompleted ? Icons.check_circle : Icons.assignment,
            color: _getPriorityColor(request.priority),
            size: 24,
          ),
        ),
        title: Text(
          request.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: request.isCompleted
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            decoration: request.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (request.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(request.dueDate!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(request.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(request.dueDate!),
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
            if (request.priority != Priority.low)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    request.priority,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityText(request.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(request.priority),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleRequestAction(value, request),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'toggle',
                  child: Text('Toggle Complete'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () => _toggleRequestCompletion(request),
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

  void _toggleRequestCompletion(RequestItem request) {
    setState(() {
      request.isCompleted = !request.isCompleted;
    });
  }

  void _handleRequestAction(String action, RequestItem request) {
    switch (action) {
      case 'toggle':
        _toggleRequestCompletion(request);
        break;
      case 'edit':
        _showEditRequestDialog(request);
        break;
      case 'delete':
        _showDeleteConfirmation(request);
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Requests'),
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

  void _showAddRequestDialog() {
    // TODO: Implement add request dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add request functionality coming soon!'),
        backgroundColor: AppColors.friendly,
      ),
    );
  }

  void _showEditRequestDialog(RequestItem request) {
    // TODO: Implement edit request dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit request functionality coming soon!'),
        backgroundColor: AppColors.friendly,
      ),
    );
  }

  void _showDeleteConfirmation(RequestItem request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Are you sure you want to delete "${request.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _requests.remove(request);
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

class RequestItem {
  final String id;
  final String title;
  final String description;
  final Priority priority;
  final DateTime? dueDate;
  bool isCompleted;

  RequestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
  });
}

enum Priority { low, medium, high }
