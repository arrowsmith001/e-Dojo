
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageManager{

  static StorageManager instance = StorageManager._internal();
  factory StorageManager() => instance;
  StorageManager._internal(){
    GetTempDir();
  }

  Future<Directory> GetTempDir() async {
    if(appDir == null) appDir = await getTemporaryDirectory();
    return appDir;
  }

  Directory appDir;

  Future<void> SaveFileToTemp() {

  }
}

Future<File> CacheFileForUpload(File file) async {

  Directory tempDir = StorageManager.instance.appDir == null ? await StorageManager.instance.GetTempDir() : StorageManager.instance.appDir;
  String tempPath = tempDir.path;

  String imgId = Uuid().v1();

  File newFile = new File(tempPath + '/icons/' + imgId + '.png');
  if(!(await newFile.exists())) await newFile.create(recursive: true);

  newFile = await file.copy(tempPath + '/icons/' + imgId + '.png');
  await file.delete();

  return newFile;
}