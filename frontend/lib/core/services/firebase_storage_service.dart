import 'dart:io';



import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';



class FirebaseStorageService {

  FirebaseStorageService({FirebaseStorage? storage}) : _storageOverride = storage;



  final FirebaseStorage? _storageOverride;

  FirebaseStorage? _storage;

  final ImagePicker _picker = ImagePicker();



  FirebaseStorage get _storageClient {

    return _storage ??= _storageOverride ?? FirebaseStorage.instance;

  }



  static bool get isSupported {

    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||

        defaultTargetPlatform == TargetPlatform.iOS;

  }



  Future<XFile?> pickAvatarImage() {

    return _picker.pickImage(

      source: ImageSource.gallery,

      maxWidth: 1024,

      maxHeight: 1024,

      imageQuality: 85,

    );

  }



  Future<String> uploadAvatar({

    required String userId,

    required File imageFile,

  }) async {

    if (!isSupported) {

      throw UnsupportedError(

        'Upload ảnh chỉ hỗ trợ trên Android/iOS. Hãy chạy app trên emulator hoặc điện thoại.',

      );

    }



    if (!await imageFile.exists()) {

      throw StateError('Không đọc được file ảnh đã chọn.');

    }



    final safeUserId = userId.trim();

    if (safeUserId.isEmpty) {

      throw ArgumentError('UserId không hợp lệ.');

    }



    final ref = _storageClient.ref().child('avatars/$safeUserId/avatar.jpg');



    try {

      final uploadTask = ref.putFile(

        imageFile,

        SettableMetadata(contentType: 'image/jpeg'),

      );



      final snapshot = await uploadTask;



      if (snapshot.state != TaskState.success) {

        throw FirebaseException(

          plugin: 'firebase_storage',

          code: 'upload-failed',

          message: 'Upload chưa hoàn tất (state: ${snapshot.state}).',

        );

      }



      return await snapshot.ref.getDownloadURL();

    } on FirebaseException {

      rethrow;

    }

  }

}


