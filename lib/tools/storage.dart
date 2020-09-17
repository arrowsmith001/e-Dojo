
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:edojo/classes/misc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageManager{

  // TODO Smarter caching

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

  /// Icon id to icon file lookup
  Map<String, File> cachedIcons = {};

  Map<String, File> cachedDPs = {};

  Map<String, GameScheme> cachedSchemes = {}; // TODO Put to file


  void ClearCache() {
    cachedSchemes.clear();
    cachedIcons.clear();
    cachedDPs.clear();
  }


}


Future<File> CacheImageFileForUpload(String folderName, File file) async {

  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;

  String imgId = GetUniqueIdentifier();

  File newFile = new File(tempPath + '/$folderName/' + imgId + '.png');
  if(!(await newFile.exists())) await newFile.create(recursive: true);

  if(file.path.split('.').last != 'png'){

    bool exists = await file.exists();
    print('file exists: '+exists.toString());

    newFile.writeAsBytes(await file.readAsBytes());
  }
  else
    {

      newFile = await file.copy(tempPath + '/$folderName/' + imgId + '.png');
    }


  // await file.delete();

  return newFile;
}

String GetUniqueIdentifier() {
  return Uuid().v1();
  // TODO Is this really unique?
}