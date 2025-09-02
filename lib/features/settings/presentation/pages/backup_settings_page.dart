import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/backup_service.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final BackupService _backupService = BackupService();
  List<BackupInfo> _availableBackups = [];
  bool _isLoading = false;
  bool _autoBackupEnabled = true; // This should be stored in preferences

  @override
  void initState() {
    super.initState();
    _loadAvailableBackups();
  }

  Future<void> _loadAvailableBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.getAvailableBackups();
      setState(() => _availableBackups = backups);
    } catch (e) {
      _showErrorSnackBar('Failed to load backups: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Backup actions section
            _buildBackupActionsSection(),
            const SizedBox(height: 24),

            // Restore section
            _buildRestoreSection(),
            const SizedBox(height: 24),

            // Auto backup settings
            _buildAutoBackupSection(),
            const SizedBox(height: 24),

            // Available backups
            _buildAvailableBackupsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.backup,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Backup & Restore',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your tasks, medicines, and reminders safe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backup includes all your tasks, medicines, doses, and reminders',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Backup',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createBackup,
                icon: const Icon(Icons.save_alt),
                label: const Text('Create Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportBackup,
                icon: const Icon(Icons.share),
                label: const Text('Export & Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restore Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Restore Warning',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Restoring will replace all current data. A backup of current data will be created automatically.',
                style: TextStyle(color: Colors.orange.shade700),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importBackup,
                  icon: const Icon(Icons.restore),
                  label: const Text('Import & Restore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic Backup',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto Backup',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Automatically create backups weekly',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoBackupEnabled,
                    onChanged: (value) {
                      setState(() => _autoBackupEnabled = value);
                      // TODO: Save to preferences
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              if (_autoBackupEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Automatic backups are stored locally and kept for 5 weeks',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableBackupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Backups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadAvailableBackups,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableBackups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, 
                     size: 48, 
                     color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No backups found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first backup to get started',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableBackups.length,
            itemBuilder: (context, index) {
              final backup = _availableBackups[index];
              return _buildBackupTile(backup);
            },
          ),
      ],
    );
  }

  Widget _buildBackupTile(BackupInfo backup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backup.isAutomatic ? Colors.blue.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            backup.isAutomatic ? Icons.schedule : Icons.backup,
            color: backup.isAutomatic ? Colors.blue : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          backup.fileName.replaceAll('.remindme', ''),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_formatDate(backup.createdAt)} • ${backup.sizeFormatted}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              backup.dataCount,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (backup.isAutomatic)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUTOMATIC',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restore, size: 18),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red.shade600)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleBackupAction(value as String, backup),
        ),
      ),
    );
  }

  void _handleBackupAction(String action, BackupInfo backup) async {
    switch (action) {
      case 'restore':
        await _restoreFromBackup(backup);
        break;
      case 'share':
        await _shareBackup(backup);
        break;
      case 'delete':
        await _deleteBackup(backup);
        break;
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.createBackup();
      
      if (result.isSuccess) {
        _showSuccessSnackBar('${result.message} - ${result.dataCount}');
        await _loadAvailableBackups();
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.exportBackup();
      
      if (result.isSuccess) {
        _showSuccessSnackBar('${result.message} - ${result.dataCount}');
        await _loadAvailableBackups();
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importBackup() async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Restore from Backup',
      'This will replace all current data with the backup data. A backup of your current data will be created automatically.\n\nDo you want to continue?',
      confirmText: 'Restore',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.importBackup();
      
      if (result.isSuccess) {
        _showSuccessSnackBar('${result.message} - ${result.dataCount}');
        await _loadAvailableBackups();
        
        // Show restart suggestion
        if (mounted) {
          _showRestartDialog();
        }
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to import backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromBackup(BackupInfo backup) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Restore Backup',
      'This will replace all current data with the selected backup.\n\nBackup: ${backup.fileName}\nCreated: ${_formatDate(backup.createdAt)}\nData: ${backup.dataCount}\n\nDo you want to continue?',
      confirmText: 'Restore',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      final file = File(backup.filePath);
      final result = await _backupService.restoreFromFile(file);
      
      if (result.isSuccess) {
        _showSuccessSnackBar('${result.message} - ${result.dataCount}');
        
        // Show restart suggestion
        if (mounted) {
          _showRestartDialog();
        }
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to restore backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      // Implementation will depend on your sharing mechanism
      _showInfoSnackBar('Sharing backup: ${backup.fileName}');
    } catch (e) {
      _showErrorSnackBar('Failed to share backup: $e');
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Backup',
      'Are you sure you want to delete this backup?\n\n${backup.fileName}\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      final file = File(backup.filePath);
      await file.delete();
      _showSuccessSnackBar('Backup deleted successfully');
      await _loadAvailableBackups();
    } catch (e) {
      _showErrorSnackBar('Failed to delete backup: $e');
    }
  }

  Future<bool> _showConfirmationDialog(
    String title,
    String content, {
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restore Complete'),
        content: const Text(
          'Your data has been restored successfully. It\'s recommended to restart the app to ensure all data is properly loaded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement app restart or navigation to home
            },
            child: const Text('Restart App'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
