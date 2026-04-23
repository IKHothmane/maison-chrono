import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  const StorageService();

  Future<void> uploadProductImage({required String path, required Uint8List bytes}) async {
    await Supabase.instance.client.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
  }

  Future<void> uploadProductVideo({required String path, required Uint8List bytes}) async {
    await Supabase.instance.client.storage.from('product-videos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
        );
  }

  Future<void> uploadProductVideoFile({required String path, required File file}) async {
    await Supabase.instance.client.storage.from('product-videos').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
        );
  }

  String getPublicUrl(String path) {
    return Supabase.instance.client.storage.from('product-images').getPublicUrl(path);
  }

  String getPublicVideoUrl(String path) {
    return Supabase.instance.client.storage.from('product-videos').getPublicUrl(path);
  }

  Future<void> removeProductImages(List<String> paths) async {
    await Supabase.instance.client.storage.from('product-images').remove(paths);
  }

  Future<void> removeProductVideos(List<String> paths) async {
    await Supabase.instance.client.storage.from('product-videos').remove(paths);
  }
}
