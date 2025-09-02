import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/database_helper.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/medicines/data/models/medicine_model.dart';
import '../../features/medicines/data/models/medicine_dose_model.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Creates a comprehensive backup of all user data
  Future<BackupResult> createBackup() async {
    try {
      debugPrint('🗃️ Starting comprehensive data backup...');

      // Request storage permissions
      await _requestStoragePermissions();

      // Get all data from database
      final backupData = await _collectAllData();

      // Create backup file
      final backupFile = await _createBackupFile(backupData);

      debugPrint('🗃️ ✅ Backup created successfully: ${backupFile.path}');
      
      return BackupResult.success(
        message: 'Backup created successfully',
        filePath: backupFile.path,
        dataCount: backupData.summary,
      );
    } catch (e) {
      debugPrint('🗃️ ❌ Error creating backup: $e');
      return BackupResult.error('Failed to create backup: $e');
    }
  }

  /// Exports backup and shares it with user (email, cloud storage, etc.)
  Future<BackupResult> exportBackup() async {
    try {
      debugPrint('🗃️ 📤 Exporting backup for sharing...');

      final backupResult = await createBackup();
      if (!backupResult.isSuccess) {
        return backupResult;
      }

      // Share the backup file
      await Share.shareXFiles(
        [XFile(backupResult.filePath!)],
        subject: 'RemindMe App Data Backup',
        text: 'Your RemindMe app data backup is attached. Keep this file safe to restore your data later.\n\n${backupResult.dataCount}',
      );

      return BackupResult.success(
        message: 'Backup exported successfully',
        filePath: backupResult.filePath,
        dataCount: backupResult.dataCount,
      );
    } catch (e) {
      debugPrint('🗃️ ❌ Error exporting backup: $e');
      return BackupResult.error('Failed to export backup: $e');
    }
  }

  /// Imports backup from user-selected file
  Future<BackupResult> importBackup() async {
    try {
      debugPrint('🗃️ 📥 Starting backup import...');

      // Let user select backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['remindme'],
        dialogTitle: 'Select RemindMe Backup File',
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult.error('No backup file selected');
      }

      final backupFile = File(result.files.first.path!);
      return await restoreFromFile(backupFile);
    } catch (e) {
      debugPrint('🗃️ ❌ Error importing backup: $e');
      return BackupResult.error('Failed to import backup: $e');
    }
  }

  /// Restores data from a specific backup file
  Future<BackupResult> restoreFromFile(File backupFile) async {
    try {
      debugPrint('🗃️ 🔄 Restoring from backup file: ${backupFile.path}');

      if (!await backupFile.exists()) {
        return BackupResult.error('Backup file does not exist');
      }

      // Read and parse backup file
      final backupContent = await backupFile.readAsString();
      final backupData = BackupData.fromJson(jsonDecode(backupContent));

      // Validate backup data
      final validationResult = _validateBackupData(backupData);
      if (!validationResult.isValid) {
        return BackupResult.error('Invalid backup file: ${validationResult.error}');
      }

      // Create backup of current data before restore
      await _createPreRestoreBackup();

      // Clear existing data (with confirmation)
      await _clearAllData();

      // Restore all data
      await _restoreAllData(backupData);

      debugPrint('🗃️ ✅ Backup restored successfully');
      
      return BackupResult.success(
        message: 'Backup restored successfully',
        dataCount: backupData.summary,
      );
    } catch (e) {
      debugPrint('🗃️ ❌ Error restoring backup: $e');
      return BackupResult.error('Failed to restore backup: $e');
    }
  }

  /// Creates automatic backup (can be scheduled)
  Future<BackupResult> createAutomaticBackup() async {
    try {
      debugPrint('🗃️ 🤖 Creating automatic backup...');

      // Get app documents directory for automatic backups
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Clean old automatic backups (keep only last 5)
      await _cleanOldBackups(backupDir);

      // Get all data
      final backupData = await _collectAllData();

      // Create backup with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('${backupDir.path}/auto_backup_$timestamp.remindme');
      
      await backupFile.writeAsString(
        jsonEncode(backupData.toJson()),
        encoding: utf8,
      );

      debugPrint('🗃️ ✅ Automatic backup created: ${backupFile.path}');
      
      return BackupResult.success(
        message: 'Automatic backup created',
        filePath: backupFile.path,
        dataCount: backupData.summary,
      );
    } catch (e) {
      debugPrint('🗃️ ❌ Error creating automatic backup: $e');
      return BackupResult.error('Failed to create automatic backup: $e');
    }
  }

  /// Lists all available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final backups = <BackupInfo>[];

      // Get automatic backups
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');
      
      if (await backupDir.exists()) {
        final autoBackups = await backupDir
            .list()
            .where((entity) => entity.path.endsWith('.remindme'))
            .cast<File>()
            .toList();

        for (final file in autoBackups) {
          final stat = await file.stat();
          final content = await file.readAsString();
          final data = BackupData.fromJson(jsonDecode(content));
          
          backups.add(BackupInfo(
            fileName: file.path.split('/').last,
            filePath: file.path,
            createdAt: data.metadata.createdAt,
            size: stat.size,
            dataCount: data.summary,
            isAutomatic: true,
          ));
        }
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      debugPrint('🗃️ ❌ Error getting available backups: $e');
      return [];
    }
  }

  Future<BackupData> _collectAllData() async {
    debugPrint('🗃️ 📊 Collecting all data from database...');

    final db = await _databaseHelper.database;

    // Get all tasks
    final tasksData = await db.query(DatabaseHelper.tableTask);
    final tasks = tasksData.map((map) => TaskModel.fromMap(map)).toList();
    debugPrint('🗃️ 📋 Found ${tasks.length} tasks');

    // Get all medicines
    final medicinesData = await db.query(DatabaseHelper.tableMedicine);
    final medicines = medicinesData.map((map) => MedicineModel.fromMap(map)).toList();
    debugPrint('🗃️ 💊 Found ${medicines.length} medicines');

    // Get all medicine doses
    final dosesData = await db.query(DatabaseHelper.tableMedicineDose);
    final doses = dosesData.map((map) => MedicineDoseModel.fromMap(map)).toList();
    debugPrint('🗃️ 💉 Found ${doses.length} medicine doses');

    final metadata = BackupMetadata(
      appVersion: '1.0.0', // You can get this from package_info
      createdAt: DateTime.now(),
      deviceInfo: await _getDeviceInfo(),
      databaseVersion: DatabaseHelper.databaseVersion,
    );

    return BackupData(
      metadata: metadata,
      tasks: tasks,
      medicines: medicines,
      medicineDoses: doses,
    );
  }

  Future<File> _createBackupFile(BackupData backupData) async {
    Directory? directory;
    String directoryType = "app-specific";
    
    if (Platform.isAndroid) {
      // Check if we have MANAGE_EXTERNAL_STORAGE permission
      final hasManageStorage = await Permission.manageExternalStorage.isGranted;
      
      if (hasManageStorage) {
        // Use Downloads directory for broader accessibility
        directory = await getDownloadsDirectory();
        directoryType = "Downloads";
        debugPrint('🗃️ 📁 Using Downloads directory (broad access granted)');
      }
      
      if (directory == null) {
        // Fallback to app-specific external directory (no permissions needed)
        directory = await getExternalStorageDirectory();
        directoryType = "app-specific external";
        debugPrint('🗃️ 📁 Using app-specific external directory');
      }
      
      if (directory == null) {
        // Final fallback to documents directory
        directory = await getApplicationDocumentsDirectory();
        directoryType = "app documents";
        debugPrint('🗃️ 📁 Using app documents directory');
      }
    } else {
      // For iOS and other platforms
      directory = await getApplicationDocumentsDirectory();
      directoryType = "documents";
    }
    
    final backupDir = Directory('${directory.path}/RemindMe_Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // Create filename with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'RemindMe_Backup_$timestamp.remindme';
    final backupFile = File('${backupDir.path}/$fileName');

    // Write backup data as JSON
    await backupFile.writeAsString(
      jsonEncode(backupData.toJson()),
      encoding: utf8,
    );

    debugPrint('🗃️ ✅ Backup saved to $directoryType directory: ${backupFile.path}');
    return backupFile;
  }

  ValidationResult _validateBackupData(BackupData backupData) {
    try {
      // Check if metadata exists and is valid
      if (backupData.metadata.createdAt.isAfter(DateTime.now().add(Duration(days: 1)))) {
        return ValidationResult.invalid('Backup file appears to be from the future');
      }

      // Check if tasks are valid
      for (final task in backupData.tasks) {
        if (task.id.isEmpty || task.title.isEmpty) {
          return ValidationResult.invalid('Invalid task data found');
        }
      }

      // Check if medicines are valid
      for (final medicine in backupData.medicines) {
        if (medicine.id.isEmpty || medicine.name.isEmpty) {
          return ValidationResult.invalid('Invalid medicine data found');
        }
      }

      // Check if medicine doses are valid
      for (final dose in backupData.medicineDoses) {
        if (dose.id.isEmpty || dose.medicineId.isEmpty) {
          return ValidationResult.invalid('Invalid medicine dose data found');
        }
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Error validating backup data: $e');
    }
  }

  Future<void> _createPreRestoreBackup() async {
    try {
      debugPrint('🗃️ 🛡️ Creating pre-restore backup...');
      
      final directory = await getApplicationDocumentsDirectory();
      final preRestoreDir = Directory('${directory.path}/pre_restore_backups');
      
      if (!await preRestoreDir.exists()) {
        await preRestoreDir.create(recursive: true);
      }

      final backupData = await _collectAllData();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('${preRestoreDir.path}/pre_restore_$timestamp.remindme');
      
      await backupFile.writeAsString(
        jsonEncode(backupData.toJson()),
        encoding: utf8,
      );

      debugPrint('🗃️ ✅ Pre-restore backup created');
    } catch (e) {
      debugPrint('🗃️ ⚠️ Failed to create pre-restore backup: $e');
      // Don't throw error here, continue with restore
    }
  }

  Future<void> _clearAllData() async {
    debugPrint('🗃️ 🧹 Clearing all existing data...');

    final db = await _databaseHelper.database;

    // Clear in correct order (foreign key constraints)
    await db.delete(DatabaseHelper.tableMedicineDose);
    await db.delete(DatabaseHelper.tableMedicine);
    await db.delete(DatabaseHelper.tableTask);

    debugPrint('🗃️ ✅ All data cleared');
  }

  Future<void> _restoreAllData(BackupData backupData) async {
    debugPrint('🗃️ 🔄 Restoring all data...');

    final db = await _databaseHelper.database;

    // Restore tasks
    for (final task in backupData.tasks) {
      await db.insert(
        DatabaseHelper.tableTask,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint('🗃️ ✅ Restored ${backupData.tasks.length} tasks');

    // Restore medicines
    for (final medicine in backupData.medicines) {
      await db.insert(
        DatabaseHelper.tableMedicine,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint('🗃️ ✅ Restored ${backupData.medicines.length} medicines');

    // Restore medicine doses
    for (final dose in backupData.medicineDoses) {
      await db.insert(
        DatabaseHelper.tableMedicineDose,
        dose.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint('🗃️ ✅ Restored ${backupData.medicineDoses.length} medicine doses');

    debugPrint('🗃️ ✅ All data restored successfully');
  }

  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final backupFiles = await backupDir
          .list()
          .where((entity) => entity.path.endsWith('.remindme'))
          .cast<File>()
          .toList();

      if (backupFiles.length > 5) {
        // Sort by modification time
        backupFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // Delete oldest backups
        final filesToDelete = backupFiles.take(backupFiles.length - 5);
        for (final file in filesToDelete) {
          await file.delete();
          debugPrint('🗃️ 🗑️ Deleted old backup: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('🗃️ ⚠️ Error cleaning old backups: $e');
    }
  }

  Future<void> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      try {
        // For Android 13+, we need MANAGE_EXTERNAL_STORAGE for broad file access
        // or use app-specific directories which don't require permissions
        final manageStorageStatus = await Permission.manageExternalStorage.status;
        
        if (manageStorageStatus.isDenied) {
          // Request MANAGE_EXTERNAL_STORAGE permission
          // This will open settings page for user to grant permission
          await Permission.manageExternalStorage.request();
          debugPrint('🗃️ 🔑 MANAGE_EXTERNAL_STORAGE permission requested');
        }
        
        // Also check for notification permission since we're here
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('🗃️ ⚠️ Permission request failed, using app-specific directory: $e');
      }
    }
  }

  /// Check storage permission status and return user-friendly information
  Future<StoragePermissionInfo> getStoragePermissionInfo() async {
    if (!Platform.isAndroid) {
      return StoragePermissionInfo(
        hasFullAccess: true,
        canAccessDownloads: true,
        message: 'Full storage access available',
        recommendedAction: null,
      );
    }

    final manageStorageStatus = await Permission.manageExternalStorage.status;
    
    if (manageStorageStatus.isGranted) {
      return StoragePermissionInfo(
        hasFullAccess: true,
        canAccessDownloads: true,
        message: 'Full storage access granted - backups saved to Downloads folder',
        recommendedAction: null,
      );
    } else if (manageStorageStatus.isPermanentlyDenied) {
      return StoragePermissionInfo(
        hasFullAccess: false,
        canAccessDownloads: false,
        message: 'Storage permission permanently denied - using app-specific storage',
        recommendedAction: 'Open app settings to grant "All files access" permission',
      );
    } else {
      return StoragePermissionInfo(
        hasFullAccess: false,
        canAccessDownloads: false,
        message: 'Limited storage access - using app-specific storage',
        recommendedAction: 'Grant "All files access" permission for Downloads folder access',
      );
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }
}

// Data models for backup
class BackupData {
  final BackupMetadata metadata;
  final List<TaskModel> tasks;
  final List<MedicineModel> medicines;
  final List<MedicineDoseModel> medicineDoses;

  BackupData({
    required this.metadata,
    required this.tasks,
    required this.medicines,
    required this.medicineDoses,
  });

  String get summary {
    return '${tasks.length} tasks, ${medicines.length} medicines, ${medicineDoses.length} doses';
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'medicines': medicines.map((medicine) => medicine.toJson()).toList(),
      'medicineDoses': medicineDoses.map((dose) => dose.toJson()).toList(),
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      metadata: BackupMetadata.fromJson(json['metadata']),
      tasks: (json['tasks'] as List)
          .map((taskJson) => TaskModel.fromJson(taskJson))
          .toList(),
      medicines: (json['medicines'] as List)
          .map((medicineJson) => MedicineModel.fromJson(medicineJson))
          .toList(),
      medicineDoses: (json['medicineDoses'] as List)
          .map((doseJson) => MedicineDoseModel.fromJson(doseJson))
          .toList(),
    );
  }
}

class BackupMetadata {
  final String appVersion;
  final DateTime createdAt;
  final String deviceInfo;
  final int databaseVersion;

  BackupMetadata({
    required this.appVersion,
    required this.createdAt,
    required this.deviceInfo,
    required this.databaseVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'databaseVersion': databaseVersion,
    };
  }

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      appVersion: json['appVersion'],
      createdAt: DateTime.parse(json['createdAt']),
      deviceInfo: json['deviceInfo'],
      databaseVersion: json['databaseVersion'],
    );
  }
}

class BackupResult {
  final bool isSuccess;
  final String message;
  final String? filePath;
  final String? dataCount;

  BackupResult._({
    required this.isSuccess,
    required this.message,
    this.filePath,
    this.dataCount,
  });

  factory BackupResult.success({
    required String message,
    String? filePath,
    String? dataCount,
  }) {
    return BackupResult._(
      isSuccess: true,
      message: message,
      filePath: filePath,
      dataCount: dataCount,
    );
  }

  factory BackupResult.error(String message) {
    return BackupResult._(
      isSuccess: false,
      message: message,
    );
  }
}

class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int size;
  final String dataCount;
  final bool isAutomatic;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.size,
    required this.dataCount,
    required this.isAutomatic,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) => ValidationResult._(false, error);
}

class StoragePermissionInfo {
  final bool hasFullAccess;
  final bool canAccessDownloads;
  final String message;
  final String? recommendedAction;

  StoragePermissionInfo({
    required this.hasFullAccess,
    required this.canAccessDownloads,
    required this.message,
    this.recommendedAction,
  });
}
