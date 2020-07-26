import 'dart:io';
import 'dart:math' as math;
import 'package:edojo/pages/schemes.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';

import 'misc.dart';


// Serialize?
class DataModel {

  // AUTH DATA

  /// The signed in identity
  User user;

  /// Sets the user
  void setUser(User user) {
    print('setUser: '+user.toString());
    this.user = user;
  }

  /// Asks whether or not user account is fully set up yet
  bool isUserSetUp()
  {
    return (user != null && user.meta.userName != null);
  }

  // APP STATE DATA //
  bool savingData = false;

  List<SchemeMetadata> schemesEditing = [];
  List<SchemeMetadata> schemesOwned = [];

  /// Determines state of scheme editor
  SchemeEditorState schemeEditorState = new SchemeEditorState();

  /// Asks if schemes currently being edited are loaded
  bool areSchemeEditsLoaded() {
    if((user.schemesInEditor == null || user.schemesInEditor.length == 0) && schemesEditing.length == 0)
      {
        return true;
      }

    if(user.schemesInEditor != null && user.schemesInEditor.length == schemesEditing.length)
      {
        return true;
      }

    return false;
  }

  bool hasSchemeMetaEditing(String code) {
    for(SchemeMetadata gsm in schemesEditing) {if(gsm.schemeID == code) return true;}
    return false;
  }

  bool hasSchemeMetaOwned(String code) {
    for(SchemeMetadata gsm in schemesOwned) {if(gsm.schemeID == code) return true;}
    return false;
  }

  void UpdateOwnedSchemeEditsWithSchemeInEditor(GameScheme schemeClone) {

    if(user.schemesInEditor == null) user.schemesInEditor = {};

    if(!user.schemesInEditor.keys.contains(schemeClone.meta.schemeID))
      {
        user.schemesInEditor.addAll({schemeClone.meta.schemeID : ''});
      }
  }

  /// List of schemes in shop browser
  List<SchemeMetadata> schemesInShopBrowser = [];

  void EditQueriedSchemes(List<SchemeMetadata> list, bool reset) {
    if(reset)
      {
        schemesInShopBrowser = list;
      }
    else
      {
        schemesInShopBrowser.addAll(list);
      }

  }

  bool isSchemeOwned(String schemeId) {
    if(user == null || user.schemesOwned == null) return false;
    return user.schemesOwned.containsKey(schemeId);
  }



}

class SchemeEditorState
{

  /// The scheme that is currently equipped in the editor
  GameScheme schemeInEditor;// = GameScheme.initialGrid('', '', 2, 5);

  /// The current selection in the grid of the selected scheme
  GridSelection schemeEditorGridSelection;// = new GridSelection();

  /// Whether grid is in swap mode or not
  bool swapMode = false;

  /// Scheme
  int schemeEditorPageNum = 0;

  Future<void> SaveCurrentScheme()
  {
    // TODO Convert scheme to json, add to a list for uploading
  }

  void EditExistingScheme(GameScheme scheme)
  {
    schemeInEditor = scheme;
    schemeEditorGridSelection = new GridSelection();
    swapMode = false;
  }

  Future<void> EditNewScheme(NewGameInfo info) async {

    File file = info.icon;
    String imgId;
    if(file != null)
      {
        File newFile = await CacheImageFileForUpload('icons',file);
        file = newFile;
        imgId = newFile.path.split('/').last.split('.').first;
      }
    else file = null;

    schemeInEditor = GameScheme.initialGrid(new SchemeMetadata.newScheme(info.name, info.nickname, imgId), 2, 6);
    schemeInEditor.SetImage(file);

    schemeEditorGridSelection = new GridSelection();
    swapMode = false;

    print('EditNewScheme called');
  }

  void TrySelectCell(GridSelection gridSelection) {
    if(gridSelection.x <= schemeInEditor.grid.dim.maxRow && gridSelection.y <= schemeInEditor.grid.dim.maxCol)
    {
      if(!swapMode)
      {
        this.schemeEditorGridSelection = gridSelection;

      }
      else // Swap current and new selection
          {
        schemeInEditor.grid.Swap(schemeEditorGridSelection, gridSelection);

        this.schemeEditorGridSelection = gridSelection;
        swapMode = false;
      }


    }


  }

  void SchemeEditorGridOperation(Ops op, GridOps gridOp) {

    SelectGrid grid = schemeInEditor.grid;

    if(gridOp == GridOps.row) {
      if(op == Ops.add) {
        grid.addRow();
      }
      else if(op == Ops.remove) {
        schemeInEditor.grid.removeRow();
        schemeEditorGridSelection.x = math.min(schemeEditorGridSelection.x, grid.dim.maxRow);
      }
    }
    else if(gridOp == GridOps.column) {
      if(op == Ops.add) {
        schemeInEditor.grid.addColumn();
      }
      else if(op == Ops.remove) {
        schemeInEditor.grid.removeColumn();
        schemeEditorGridSelection.y = math.min(schemeEditorGridSelection.y, grid.dim.maxCol);
      }
    }

  }

  Future<void> AddFighterToSchemeInEditor(Map<String, dynamic> map) async {

    String name = map['Name'];
    String imgId = null;

    List list = map['Icon'];
    if(list != null && list.isNotEmpty)
    {
      File newFile = await CacheImageFileForUpload('icons',list[0]);
      map['Icon'] = newFile;
      imgId = newFile.path.split('/').last.split('.').first;
    }
    else map['Icon'] = null;


    List<String> variants;
    if(map['Variations'] > 0)
    {
      variants = [];

      for(int i = 0; i < map['Variations']; i++)
      {
        variants.add(map['Variant$i']);
      }
    }

    FighterScheme f = new FighterScheme(name, imgId, variants);
    f.SetImage(map['Icon']);

    if(schemeEditorPageNum == 0)
    {
      schemeInEditor.AddFighter(f);
    }
    else
    {
      schemeInEditor.AddFighterAt(f, schemeEditorGridSelection.x, schemeEditorGridSelection.y);
    }

  }

  void ToggleSwapMode(GridSelection gridSelection) {
    swapMode = !swapMode;
  }

  String GetFighterAtSelectionString() {

    if(schemeInEditor == null) return '';
    Square squ = schemeInEditor.grid.getSquare(schemeEditorGridSelection.x, schemeEditorGridSelection.y);

    if(squ.fighter == null) return '<Empty>';
    else return squ.fighter.fighterName;

  }

  Square GetSelection() {
    if(schemeInEditor == null) return null;
    return schemeInEditor.grid.getSquare(schemeEditorGridSelection.x, schemeEditorGridSelection.y);
  }

  Future<void> EditFighter(FighterScheme fighter, Map<String, dynamic> map) async {

    String name = map['Name'];

    String imgId = null;
    List list = map['Icon'];
    if(list != null && list.isNotEmpty)
    {
      File newFile = await CacheImageFileForUpload('icons',list[0]);
      map['Icon'] = newFile;
      imgId = newFile.path.split('/').last.split('.').first;
    }
    else map['Icon'] = null;

    List<String> variants;

    fighter.fighterName = name;
    fighter.iconImgId = imgId;
    fighter.SetImage(map['Icon']);
    fighter.variants = variants;

    // TODO Validate name for conflicts
  }
}

class GridSelection{

  GridSelection();
  GridSelection.init(int i, int j){
   this.x = i;
   this.y = j;
  }


  bool compare(int x, int y)
  {
    return (this.x == x && this.y == y);
  }
  int x = 0;
  int y = 0;

}