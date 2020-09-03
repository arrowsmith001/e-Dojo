// MAIN OBJECTS
import 'dart:io';
import 'dart:ui';

import 'package:edojo/classes/data_model.dart';
import 'package:edojo/pages/_challenges.dart';
import 'package:edojo/tools/assets.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/generated/i18n.dart';
part 'misc.g.dart';


@JsonSerializable()
class User
{

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  UserMetadata meta = new UserMetadata();

  User();

  User.init(this.meta);

  void SetNamesAndJoinDate(String username, String displayName, DateTime joinDate)
  {
    this.meta.userName = username;
    this.meta.displayName = displayName;
    this.meta.joinDate = joinDate;
  }

  // Stores as codes
  Map<String, String> friendList;
  Map<String, String> friendsPendingResponse;
  Map<String, String> friendRequests;

  // Stores as codes

  // SchemesInEditor
  Map<String, String> schemesInEditor;
  Map<String, String> schemesOwned;

  // Challenge
  Map<String, String> challengeRequests;
  String challengeInProgressId;

  static const String FRIEND_LIST = 'friendList';
  static const String FRIENDS_PENDING_RESPONSE = 'friendsPendingResponse';
  static const String FRIEND_REQUESTS = 'friendRequests';
  static const String CHALLENGE_REQUESTS = 'challengeRequests';

  static const String SCHEMES_IN_EDITOR = 'schemesInEditor';
  static const String SCHEMES_OWNED = 'schemesOwned';

  static const String CHALLENGE_IN_PROGRESS = 'challengeInProgressId';

  @override String toString()
  {
    return (meta.userName ?? 'no userName') + ' | '
        + (meta.displayName ?? 'no displayName') + ' | '
        + (meta.email ?? 'no email') + ' | '
        + (meta.uid ?? 'no uid');
  }

  List<String> GetSchemeEditCodes() {
    return schemesInEditor == null ? null : schemesInEditor.keys.toList();
  }



  List<String> GetSchemesOwnedCodes() {
    return schemesOwned == null ? null : schemesOwned.keys.toList();
  }

  Map<String,String> GetFriendCodes(FriendListType type) {
    switch(type)
    {
      case FriendListType.FullFriends:
        return friendList;
        break;
      case FriendListType.FriendRequests:
        return friendRequests;
        break;
      case FriendListType.FriendsPending:
        return friendsPendingResponse;
        break;
    }

  }

  List<String> GetChallengeCodes() {
    return challengeRequests == null ? null : challengeRequests.values.toList();
  }


}

enum FriendListType{
  FullFriends,
  FriendRequests,
  FriendsPending
}

@JsonSerializable()
class UserMetadata{
  factory UserMetadata.fromJson(Map<String, dynamic> json) => _$UserMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$UserMetadataToJson(this);

  UserMetadata();
  UserMetadata.basic(this.email, this.uid);
  UserMetadata.full(UserMetadata umd){
    this.userName = umd.userName;
    this.displayName = umd.displayName;
    this.email = umd.email;
    this.uid = umd.uid;
    this.joinDate = umd.joinDate;
    this.imgId = umd.imgId;
    this.img = umd.img;
    this.imgFile = umd.imgFile;
  }

  String userName;
  String displayName;
  String email;
  String uid;
  DateTime joinDate;
  String imgId;

  @JsonKey(ignore: true)
  Image img;
  @JsonKey(ignore: true)
  File imgFile;

  Image GetImage() {
    if(imgId == null) return Image.asset(Assets.DEFAULT_USER);
    if(img != null) return img;
    if(imgFile != null) return Image.file(imgFile);
    return Image.asset(Assets.BROKEN_LINK);
  }

}

class UserMetadataWithKey extends UserMetadata{
  // Unique key identifier, usually null
  String key;

  UserMetadataWithKey(UserMetadata umd, this.key) : super.full(umd);
  void SetKey(String key) {this.key = key;}
  String GetKey() => this.key;
}

@JsonSerializable()
class SchemeMetadata{
  factory SchemeMetadata.fromJson(Map<String, dynamic> json) => _$SchemeMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SchemeMetadataToJson(this);

  SchemeMetadata();
  SchemeMetadata.newScheme(this.gameName, this.gameNickName, this.iconImgId);
  SchemeMetadata.fromQuery(this.schemeID, this.gameName, this.gameNickName, this.iconImgId, this.iconImgFile, this.upvotes);

  String schemeID;
  String gameName;
  String gameNickName;
  int rosterNum = 0;
  int upvotes = 0;
  int releaseYear;
  String iconImgId;

  @JsonKey(ignore: true)
  Image iconImg;
  @JsonKey(ignore: true)
  File iconImgFile;

  Map<String, dynamic> GetMap() {
    return {'databaseRef' : schemeID ?? '',
      'iconRef' : iconImgId ?? '',
      'name' : gameName ?? '',
      'nickname' : gameNickName ?? '',
      'upvotes' : upvotes };
  }

  Image GetGameImage() {
    if(iconImgId == null) return Image.asset(Assets.DEFAULT_GAME);
    if(iconImg != null) return iconImg;
    if(iconImgFile != null) return Image.file(iconImgFile);
    return Image.asset(Assets.BROKEN_LINK);
  }
}


enum GridOps{
  column, row
}

@JsonSerializable()
class GameScheme
{
  factory GameScheme.fromJson(Map<String, dynamic> json) => _$GameSchemeFromJson(json);
  Map<String, dynamic> toJson() => _$GameSchemeToJson(this);

  static GameScheme jsonClone(GameScheme toClone){
    Map<String, dynamic> json = toClone.toJson();
    return new GameScheme.fromJson(json);
  }

  GameScheme(this.meta);

  GameScheme.initialGrid(this.meta, int rows, int cols){

    if(grid == null) grid = new SelectGrid();
    for(int i = 0; i<rows; i++)
    {
      grid.addRow();
    }
    for(int j = 0; j<cols; j++)
    {
      grid.addColumn();
    }
  }

  SchemeMetadata meta = new SchemeMetadata();

  List<FighterScheme> roster;
  SelectGrid grid;

  Image GetGameImage()
  {
    return meta.GetGameImage();
  }


  void SetSchemeID(String schemeID) {
    this.meta.schemeID = schemeID;

    for(FighterScheme f in roster)
    {
      f.associatedGameID = schemeID;
    }
  }
  void AddFighter(FighterScheme f) {
    if(roster == null) roster = [];
    if(roster.indexOf(f) != -1) return;
    if(meta.schemeID != null) {f.associatedGameID = meta.schemeID;}
    _AddFighterToRoster(f);

    _AddFighterToGrid(f);
  }
  void AddFighterAt(FighterScheme f, int row, int col) {
    if(roster == null) roster = [];
    if(roster.indexOf(f) != -1) return;
    if(meta.schemeID != null) {f.associatedGameID = meta.schemeID;}
    _AddFighterToRoster(f);

    _AddFighterToGridAt(f, row, col);
  }
  void _AddFighterToRoster(FighterScheme f) {
      if(roster == null) { roster = [];  }
      roster.add(f);
  }
  void _AddFighterToGrid(FighterScheme f) {
    if(grid == null) grid = new SelectGrid();
    grid.add(f);

  }
  void _AddFighterToGridAt(FighterScheme f, int row, int col) {
    if(grid == null) grid = new SelectGrid();
    grid.addAt(f, row, col);
  }
  int GetRosterLength() {
    if(roster == null) return 0;
    else return roster.length;
  }

  /// Deletes grid and images to make for a significantly smaller upload. Decent workaround for unnecessary storage space, for now. Must be called before uploading.
  void ClearVarsForUpload() {
    this.grid = null;
    this.meta.iconImg = null;
    this.meta.iconImgFile = null;
    for(FighterScheme f in roster) {
      f.iconImg = null;
      f.iconImgFile = null;
    }
  }

  /// Instantiates grid for after a gridless version has been downloaded. Must be called when downloaded.
  void MakeGridFromUpload() {
    this.grid = new SelectGrid();
    for(FighterScheme f in this.roster) {
        grid.addAt(f, f.gridX, f.gridY);
      }
  }

  void SetImage(File iconImgFile){
    if(iconImgFile != null) {
      this.meta.iconImgFile = iconImgFile;
      this.meta.iconImg = Image.file(iconImgFile);
    }
    else this.meta.iconImg = Image.asset(Assets.DEFAULT_GAME);
  }

  SchemeMetadata GetMeta() {
    return meta;
  }


}

@JsonSerializable()
class SelectGrid {
  factory SelectGrid.fromJson(Map<String, dynamic> json) => _$SelectGridFromJson(json);
  Map<String, dynamic> toJson() => _$SelectGridToJson(this);

  SelectGrid();

  List<List<Square>> selectGrid;

  Dimensions dim = new Dimensions.empty();

  void addColumn() {
    print('${dim.maxRow} ${dim.maxCol}');
    if(selectGrid == null)
    {
      _GridInit(null);
    }
    else
      {
        for(List<Square> row in selectGrid)
          {
            print('len ${row.length}');
            row.add(new Square.empty());
          }

        dim.maxCol++;
      }

  }
  void addRow() {
    print('${dim.maxRow} ${dim.maxCol}');
    if(selectGrid == null)
    {
      _GridInit(null);
    }
    else
    {
      List<Square> list = new List<Square>();
      for(int i = 0; i <= dim.maxCol; i++)
        {
          list.add(new Square.empty());
        }

      selectGrid.add(list);

      dim.maxRow++;
    }

  }
  void add(FighterScheme f) {
    if(selectGrid == null)
    {
      _GridInit(f);
      return;
    }

    for(int i = 0; i < dim.maxRow; i++)
      {
        for(int j = 0; j < dim.maxCol; j++)
        {
          if(selectGrid[i][j].fighter == null)
            {
              selectGrid[i][j].fighter = f;
              f.SetFighterXY(i, j);
              return; // job done
            }
        }
      }

    // If this far, grid is full
    addRow();

    print('${f.fighterName} AddingAt: ${dim.maxRow - 1} ${0}');
    selectGrid[dim.maxRow - 1][0].fighter = f;
    return;
  }

  void addAt(FighterScheme f, int row, int col) {
    if(selectGrid == null)
    {
      _GridInit(null);
    }


    while(dim.maxRow < row) {addRow();}
    while(dim.maxCol < col) {addColumn();}

    print('dim ${dim.maxRow} ${dim.maxCol}');
    print('${f.fighterName} AddingAt: ${row} ${col}');

    selectGrid[row][col].fighter = f;
    f.SetFighterXY(row, col);
  }
  Square getSquare(int x, int y) {
    try{ return selectGrid[x][y]; }
    catch(e) { return null; }
  }
  void _GridInit(FighterScheme f) {
    Square squ = (f == null ? Square.empty() : Square(f));

    selectGrid = [ [squ] ];
    dim.init();
//    List<Square> inner = new List();
//    inner.add(squ);
//
//    selectGrid = new List();
//    selectGrid.add(inner);
  }
  void removeRow() {
    print('${dim.maxRow} ${dim.maxCol}');
    if(dim.maxRow == 1) return;

    for(Square squ in selectGrid[dim.maxRow])
      {
        if(squ.fighter != null) return;
      }

    selectGrid.removeLast();
    dim.maxRow--;
  }
  void removeColumn() {

    print('${dim.maxRow} ${dim.maxCol}');

    if(dim.maxCol == 1) return;

    for(int i = 0; i <= dim.maxRow; i++)
    {
      List<Square> list = selectGrid[i];
      print('len' + list.length.toString());
      if(list[dim.maxCol].fighter != null) return;
    }

    for(int i = 0; i <= dim.maxRow; i++)
    {
      List<Square> list = selectGrid[i];
      list.removeLast();
    }

    dim.maxCol--;
  }
  void Swap(GridSelection sel1, GridSelection sel2) {

    Square squ1 = selectGrid[sel1.x][sel1.y];
    Square squ2 = selectGrid[sel2.x][sel2.y];

    selectGrid[sel1.x][sel1.y] = squ2;
    selectGrid[sel2.x][sel2.y] = squ1;

    if(squ1.fighter != null) squ1.fighter.SetFighterXY(sel2.x, sel2.y);
    if(squ2.fighter != null) squ2.fighter.SetFighterXY(sel1.x, sel1.y);
  }

}

@JsonSerializable()
class Dimensions{
  factory Dimensions.fromJson(Map<String, dynamic> json) => _$DimensionsFromJson(json);
  Map<String, dynamic> toJson() => _$DimensionsToJson(this);

  int maxRow;
  int maxCol;

  Dimensions.empty();
  Dimensions(this.maxRow, this.maxCol);

  void init()
  {
    maxRow = 0;
    maxCol = 0;
  }

  @override
  String toString()
  {
    return '$maxRow $maxCol';
  }
}

@JsonSerializable()
class Square{
  factory Square.fromJson(Map<String, dynamic> json) => _$SquareFromJson(json);
  Map<String, dynamic> toJson() => _$SquareToJson(this);

  Square.empty();
  Square(this.fighter);

  Image GetImage()
  {
    return fighter != null ? fighter.GetFighterImage() : Image.asset(Assets.DEFAULT_SQUARE, color: Color.fromRGBO(0, 0, 0, 0.3),);
  }


  FighterScheme fighter;

  String GetName() {
    if(fighter == null) return '';
    else return fighter.fighterName;
  }
}

@JsonSerializable()
class FighterScheme {
  factory FighterScheme.fromJson(Map<String, dynamic> json) => _$FighterSchemeFromJson(json);
  Map<String, dynamic> toJson() => _$FighterSchemeToJson(this);

  int gridX;
  int gridY;

  String associatedGameID;
  String fighterID;

  FighterScheme(this.fighterName, this.iconImgId, this.variants);
  FighterScheme.withVariants(this.fighterName, this.variants);

  void SetImage(File iconImgFile){
    if(iconImgFile != null) {
      this.iconImgFile = iconImgFile;
      this.iconImg = Image.file(iconImgFile);
    }
    else this.iconImg = Image.asset(Assets.DEFAULT_FIGHTER);
  }

  String fighterName;

  /// No path, no file ext
  String iconImgId;

  @JsonKey(ignore: true)
  Image iconImg;
  @JsonKey(ignore: true)
  File iconImgFile;

  List<String> variants;

  void SetFighterID(String fighterID)
  {
    this.fighterID = fighterID;
  }

  void SetFighterXY(int x, int y){this.gridX = x; this.gridY = y;}


  Image GetFighterImage()
  {
    return iconImg != null ? iconImg : Image.asset(Assets.BROKEN_LINK);
  }

  // TODO Map to grid position
}

@JsonSerializable()
class Challenge{


  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);
  Map<String, dynamic> toJson() => _$ChallengeToJson(this);

  factory Challenge.fromInfo(ChallengeInfo info, String challengeRequestKey) {
    Challenge c = new Challenge();

    c.player1 = info.challenger.meta;
    c.player2 = info.challengee;
    c.player1Username = c.player1.userName;
    c.player2Username = c.player2.userName;

    c.player1Accepted = true;

    c.schemeId = info.schemeEquipped.schemeID;
    c.schemeName = info.schemeEquipped.gameName;
    c.schemeImgId = info.schemeEquipped.iconImgId;
    c.schemeImg = info.schemeEquipped.iconImg;
    c.schemeImgFile = info.schemeEquipped.iconImgFile;

    c.challengeId = challengeRequestKey;

    return c;
  }

  Challenge();

  // ID information
  String challengeId;

  // Scheme info
  String schemeId;
  String schemeName;
  String schemeImgId;

  @JsonKey(ignore: true)
  Image schemeImg;
  @JsonKey(ignore: true)
  File schemeImgFile;

  // Competing parties
  String player1Username;
  String player2Username;

  @JsonKey(ignore: true)
  UserMetadata player1;
  @JsonKey(ignore: true)
  UserMetadata player2;

  // Whether players are on board or not
  bool player1Accepted = false;
  bool player2Accepted = false;

  // Challenge status
  static const String STAGE_SELECTION = 'selection';
  static const String STAGE_RECORDING = 'recording';
  String status;

  static String getMyOpponent(User user, String player1id, String player2id) {
    if(player1id == user.meta.userName) return player2id;
    if(player2id == user.meta.userName) return player1id;
    return '';
  }

}

class ChallengeInfo
{
  ChallengeInfo(this.challengee, this.challenger, this.schemeEquipped);

  User challenger;
  UserMetadata challengee;
  SchemeMetadata schemeEquipped;
}
