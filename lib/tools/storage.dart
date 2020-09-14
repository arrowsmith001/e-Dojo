
import 'dart:io';

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


  Map<String, File> cachedIcons = {};
  Map<String, File> cachedDPs = {};

  Map<String, GameScheme> cachedSchemes = {}; // TODO Put to file


  void CacheData(dynamic data, CacheType type) {
    switch(type)
    {
      case CacheType.gameSchemes:
        data = data as GameScheme;
        if(!cachedSchemes.containsKey(data.meta.schemeID))
        {
          cachedSchemes.addAll({data.meta.schemeID : data});
        }
        break;

      case CacheType.icons:
        data = data as File;
        String iconId = GetFileName(data);
        if(!cachedIcons.containsKey(iconId))
        {
          cachedSchemes.addAll({iconId : data});
        }
        break;

      case CacheType.dps:
        // TODO: Handle this case.
        break;
    }


  }

  void ClearCache() {
    cachedSchemes.clear();
    cachedIcons.clear();
    cachedDPs.clear();
  }

  String GetFileName(File file) {
    String fileNameWithExt = file.path.split('/').last;
    String nameOnly = fileNameWithExt.split('.').first;
    return nameOnly;
  }

}

enum CacheType{
  icons, dps,
  gameSchemes,
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