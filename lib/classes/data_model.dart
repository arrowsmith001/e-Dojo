import 'dart:io';
import 'dart:math' as math;
import 'package:edojo/pages/_schemes.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:uuid/uuid.dart';

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
  bool isUserSetUp() {return (user != null && user.meta.userName != null);}

  // APP STATE DATA //
  bool savingData = false;

  List<SchemeMetadata> schemesEditing = [];
  List<SchemeMetadata> schemesOwned = [];

  /// List of schemes in shop browser
  List<SchemeMetadata> schemesInShopBrowser = [];

  // Scheme 'equipped' by user
  SchemeMetadata schemeEquipped;

  List<UserMetadataWithKey> friendsList = [];
  List<UserMetadataWithKey> friendRequests = [];
  List<UserMetadataWithKey> friendsPending = [];
  List<Challenge> challengesList = [];

  /// Tracks state of various pages
  SchemeEditorState schemeEditorState = new SchemeEditorState();
  ChallengeState challengeState = new ChallengeState();

  /// Asks if schemes currently being edited are loaded
  bool areSchemeEditsLoaded() {
    if((user.schemesInEditor == null || user.schemesInEditor.length == 0) && schemesEditing.length == 0) {return true;}
    if(user.schemesInEditor != null && user.schemesInEditor.length == schemesEditing.length) {return true;}
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

  bool hasFriendMeta(String userName, FriendListType type) {
    List<UserMetadataWithKey> list = _GetFriendListFromType(type);
    if(list.isEmpty) return false;
    for(UserMetadataWithKey umd in list) {if(umd.userName == userName) return true;}
    return false;
  }

  void AddFriendMeta(UserMetadataWithKey userMetaWithKey, FriendListType type) {
    List<UserMetadataWithKey> list = _GetFriendListFromType(type);
    for(UserMetadataWithKey umd in list)
    {
      if(umd.userName == userMetaWithKey.userName) return;
    }
    list.add(userMetaWithKey);
  }

  bool hasChallenge(String code) {
    if(challengesList.isEmpty) return false;
    for(Challenge ch in challengesList) {if(ch.meta.challengeId == code) return true;}
    return false;
  }

  void AddChallenge(Challenge challenge) {
    for(Challenge ch in challengesList) {if(ch.meta.challengeId == challenge.meta.challengeId) return;}
    challengesList.add(challenge);
  }

  void RemoveChallenge(String challengeId) {
    for (Challenge c in challengesList) if (c.meta.challengeId == challengeId) {
      challengesList.remove(c);
      return;
    }

  }

  void RemoveFriendMeta(String username, FriendListType type) {

    List<UserMetadata> list = _GetFriendListFromType(type);
    for(UserMetadata umd in list)
    {
      if(umd.userName == username) {
        list.remove(umd);
        return;
      }
    }

  }

  List<UserMetadataWithKey> _GetFriendListFromType(FriendListType type) {
    switch(type)
    {
      case FriendListType.FullFriends:
        return friendsList;
        break;
      case FriendListType.FriendRequests:
        return friendRequests;
        break;
      case FriendListType.FriendsPending:
        return  friendsPending;
        break;
    }
  }


}

class ChallengeState {

  Challenge challengeInProgress;

  void SelectFighter(FighterScheme fighter, int playerNum, int fighterNum) {
    if(challengeInProgress == null) return;

    challengeInProgress.SelectFighter(fighter,playerNum,fighterNum);

  }

  GameScheme GetScheme() {
    if(challengeInProgress == null) return null;
    return challengeInProgress.scheme;
  }

  FighterScheme GetFighter(int playerNum, int fighterNum) {
    if(challengeInProgress == null) return null;
    return challengeInProgress.GetFighter(playerNum, fighterNum);

  }

  Future<void> RefreshChallengeState(ChallengeStatus newState) async {
    if(challengeInProgress == null) return null;

    if(newState.player1Fighters!=null && newState.player1Fighters.length > 0)
    {
      for(FighterScheme fs in newState.player1Fighters.values)
      {
        fs.SetImage(await NetworkServiceProvider.instance.netService.GetNetworkImage(fs.iconImgId));
      }
    }

    if(newState.player2Fighters!=null && newState.player2Fighters.length > 0)
    {
      for(FighterScheme fs in newState.player2Fighters.values)
      {
        fs.SetImage(await NetworkServiceProvider.instance.netService.GetNetworkImage(fs.iconImgId));
      }
    }



    challengeInProgress.state = newState; // TODO Pick ONLY the stuff that's changed

  }

  void SetScheme(GameScheme scheme) {
    if(challengeInProgress == null) return null;
    challengeInProgress.scheme = scheme;
  }

  int entrySelection = 0;
  void ChangeEntrySelection(int fighterNum) {

    if(fighterNum == null && entrySelection != null){
      // TODO Get next blank entry (just increases for now)
      entrySelection++;
      entrySelection = entrySelection % challengeInProgress.meta.maxFighters;
    }
    else entrySelection = fighterNum;
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
    schemeInEditor.meta.maxFighters = info.teamSize;

    schemeEditorGridSelection = new GridSelection();
    swapMode = false;

    print('EditNewScheme called');
  }

  void TrySelectCell(GridSelection gridSelection) {
    if(gridSelection.x <= schemeInEditor.grid.dim.maxRow && gridSelection.y <= schemeInEditor.grid.dim.maxCol)
    {
        this.schemeEditorGridSelection = gridSelection;

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

  Future<void> AddFighterToSchemeInEditor(Map<String, dynamic> map, Square square) async {

    String name = map['Name'];
    String imgId = null;

    File file = map['Icon'];
    File newFile = await CacheImageFileForUpload('icons',file);
    map['Icon'] = newFile;
    imgId = newFile.path.split('/').last.split('.').first;


    List<String> variants;
    if(map['Variations']!=null && map['Variations'] > 0)
    {
      variants = [];

      for(int i = 0; i < map['Variations']; i++)
      {
        variants.add(map['Variant$i']);
      }
    }

    FighterScheme f = new FighterScheme(name, imgId, variants);
    f.SetImage(map['Icon']);

    schemeInEditor.AddFighterToSquare(f, square);

  }

  void ToggleSwapMode() {
    swapMode = !swapMode;
  }

  String GetFighterAtSelectionString() {

    if(schemeInEditor == null) return '';
    Square squ = schemeInEditor.grid.getSquare(schemeEditorGridSelection.x, schemeEditorGridSelection.y);

    if(squ.fighter == null) return 'ADD NEW FIGHTER';
    else return squ.fighter.fighterName;

  }

  Square GetSelection() {
    if(schemeInEditor == null) return null;
    return schemeInEditor.grid.getSquare(schemeEditorGridSelection.x, schemeEditorGridSelection.y);
  }

  Future<void> EditFighter(FighterScheme fighter, Map<String, dynamic> map) async {

    //print('Fighter img path: ' + fighter.iconImgFile.path);

    String name = map['Name'];
    File file = map['Icon'];
    int vars = map['Variations'] as int;

    String imgId = map['Icon'].path.split('/').last.split('.').first;

    if(file != fighter.iconImgFile) // If file is new...
      {
        print('NEW file...');
        File newFile = await CacheImageFileForUpload('icons',file);
        map['Icon'] = newFile;
        imgId = newFile.path.split('/').last.split('.').first;
      }

    List<String> variants = new List<String>();
    for(int i = 0; i < vars; i++){
      String k = 'Variant$i';
      String variant = map[k];
      variants.add(variant);
    }

    fighter.SetImage(map['Icon']);
    fighter.fighterName = name;
    fighter.variants = variants;
    fighter.iconImgId = imgId;

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