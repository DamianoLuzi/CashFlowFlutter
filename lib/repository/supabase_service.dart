import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
// For File
import 'package:path/path.dart' as p; // For path manipulation
import 'package:image_picker/image_picker.dart'; // For XFile

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = "receipts";

  Future<String?> uploadFileToSupabase(XFile file) async {
    try {
      // For web, you might get bytes directly. For mobile, read from path.
      final Uint8List fileBytes = await file.readAsBytes();

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
      final String path = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: false));

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(path);

    print('Public URL: $publicUrl');
    return publicUrl;
    } on StorageException catch (e) {
      print("Supabase Storage Error: ${e.message}");
      return null;
    } catch (e) {
      print("Unknown error during Supabase upload: $e");
      return null;
    }
  }



  String getPublicUrlFromSupabase(String filePath) {
    return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
  }
}