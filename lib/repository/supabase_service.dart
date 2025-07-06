import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = "receipts";

  Future<String?> uploadFileToSupabase(XFile file) async {
    try {
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