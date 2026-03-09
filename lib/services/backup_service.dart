import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static String? _getToken() {
    final box = Hive.box("auth");
    return box.get("access_token");
  }

  static Future<bool> backup() async {
    try {
      final token = _getToken();
      if (token == null) return false;

      // 1. Get Database Path
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, local_db_folder, 'workout.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return false;

      // 2. Get Images Path and Zip it
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(join(appDir.path, local_images));
      
      final tempDir = await getTemporaryDirectory();
      final zipPath = join(tempDir.path, 'images.zip');
      
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final encoder = ZipFileEncoder();
      await encoder.zipDirectory(imagesDir, filename: zipPath);
      // 3. Upload File
      final uri = Uri.parse("$base_url/user/backup/upload");
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      // Add DB file
      final dbBytes = await dbFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('db_file', dbBytes, filename: 'workout.db'));

      // Add Zip file
      final zipBytes = await File(zipPath).readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image_file', zipBytes, filename: 'images.zip'));

      final response = await request.send();

      // Clean up temp zip
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final success = response.statusCode == 200;
      if (success) {
        final box = Hive.box("auth");
        box.put("last_backup_date", DateTime.now().toString().substring(0, 16));
      }
      return success;
    } catch (e) {
      print("Backup Error: $e");
      return false;
    }
  }

  static Future<bool> restore() async {
    try {
      final token = _getToken();
      if (token == null) return false;

      final dbFolder = await getDatabasesPath();
      final dbDir = Directory(join(dbFolder, local_db_folder));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      final dbPath = join(dbDir.path, 'workout.db');

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(join(appDir.path, local_images));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Close DB before overwriting
      await WorkoutDatabaseService.instance.closeDb();

      // 1. Download DB
      final dbResponse = await http.get(
        Uri.parse("$base_url/user/backup/database"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (dbResponse.statusCode == 200) {
        final dbFile = File(dbPath);
        await dbFile.writeAsBytes(dbResponse.bodyBytes);
      } else {
         return false; // Failed to download DB
      }

      // 2. Download Images
      final imagesResponse = await http.get(
        Uri.parse("$base_url/user/backup/images"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (imagesResponse.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final zipPath = join(tempDir.path, 'images_download.zip');
        final zipFile = File(zipPath);
        await zipFile.writeAsBytes(imagesResponse.bodyBytes);

        // Unzip
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            final outFile = File(join(imagesDir.path, filename));
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
          } else {
             final outDir = Directory(join(imagesDir.path, filename));
             await outDir.create(recursive: true);
          }
        }

        await zipFile.delete();
      }

      final box = Hive.box("auth");
      box.put("last_restore_date", DateTime.now().toString().substring(0, 16));

      return true;
    } catch (e) {
      print("Restore Error: $e");
      return false;
    }
  }
}
