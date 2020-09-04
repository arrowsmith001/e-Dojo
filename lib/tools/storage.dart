
import 'dart:io';

import 'package:edojo/classes/misc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageManager{

  static StorageManager instance = StorageManager._internal();
  factory StorageManager() => instance;
  StorageManager._internal(){
    GetTempDir();
  }

  Directory appDir;
  Future<Directory> GetTempDir() async {
    if(appDir == null) appDir = await getTemporaryDirectory();
    return appDir;
  }


  Map<String, GameScheme> cachedSchemes = {};

  void AddGameSchemeToCache(GameScheme downloadedScheme) {
    if(!cachedSchemes.containsKey(downloadedScheme.meta.schemeID))
      {
        cachedSchemes.addAll({downloadedScheme.meta.schemeID : downloadedScheme});
      }
  }

}

class CachedGameScheme{
  GameScheme scheme;
  DateTime downloaded;
}

Future<File> CacheImageFileForUpload(String folderName, File file) async {

  Directory tempDir = StorageManager.instance.appDir == null ? await StorageManager.instance.GetTempDir() : StorageManager.instance.appDir;
  String tempPath = tempDir.path;

  String imgId = GetUniqueIdentifier();

  File newFile = new File(tempPath + '/$folderName/' + imgId + '.png');
  if(!(await newFile.exists())) await newFile.create(recursive: true);

  newFile = await file.copy(tempPath + '/$folderName/' + imgId + '.png');
  await file.delete();

  return newFile;
}

String GetUniqueIdentifier() {
  return Uuid().v1();
  // TODO Is this really unique?
}