// MAIN OBJECTS
import 'dart:io';
import 'dart:ui';

import 'package:edojo/classes/data_model.dart';
import 'package:edojo/tools/assets.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
part 'misc.g.dart';


@JsonSerializable()
class User
{
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User();

  User.creation(this.email, this.uid);
  User.basic(this.userName, this.displayName);

  String email;
  String uid;
  DateTime joinDate;

  String userName;
  String displayName;

  void SetNamesAndJoinDate(String username, String displayName, DateTime joinDate)
  {
    this.userName = username;
    this.displayName = displayName;
    this.joinDate = joinDate;
  }

  // Stores as codes
  Map<String, String> friendList;
  Map<String, String> friendsPendingResponse;
  Map<String, String> friendRequests;

  // Stores as codes
  Map<String, String> challengeRequests;

  // SchemesInEditor
  Map<String, String> schemesInEditor;

  static const String FRIEND_LIST = 'friendList';
  static const String FRIENDS_PENDING_RESPONSE = 'friendsPendingResponse';
  static const String FRIEND_REQUESTS = 'friendRequests';
  static const String CHALLENGE_REQUESTS = 'challengeRequests';

  static const String SCHEMES_IN_EDITOR = 'schemesInEditor';

  @override String toString()
  {
    return (userName ?? 'no userName') + ' | '
        + (displayName ?? 'no displayName') + ' | '
        + (email ?? 'no email') + ' | '
        + (uid ?? 'no uid');
  }

  List<String> GetSchemeCodes() {
    return schemesInEditor == null ? null : schemesInEditor.keys.toList();
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

  GameScheme(this.gameName, this.gameNickName);
  GameScheme.withYear(this.gameName, this.gameNickName,this.releaseYear);
  GameScheme.initialGrid(this.gameName, this.gameNickName, this.iconImgId, int rows, int cols){
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

  String schemeID;
  String gameName;
  String gameNickName;

  /// No path, no file ext
  String iconImgId;

  @JsonKey(ignore: true)
  Image iconImg;
  @JsonKey(ignore: true)
  File iconImgFile;

  int releaseYear;

  List<FighterScheme> roster;
  SelectGrid grid;

  Image GetGameImage()
  {
    return iconImg != null ? iconImg : Image.asset(Assets.BROKEN_LINK);
  }


  void SetSchemeID(String schemeID) {
    this.schemeID = schemeID;

    for(FighterScheme f in roster)
    {
      f.associatedGameID = schemeID;
    }
  }
  void AddFighter(FighterScheme f) {
    if(roster == null) roster = [];
    if(roster.indexOf(f) != -1) return;
    if(schemeID != null) {f.associatedGameID = schemeID;}
    _AddFighterToRoster(f);

    _AddFighterToGrid(f);
  }
  void AddFighterAt(FighterScheme f, int row, int col) {
    if(roster == null) roster = [];
    if(roster.indexOf(f) != -1) return;
    if(schemeID != null) {f.associatedGameID = schemeID;}
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
    this.iconImg = null;
    this.iconImgFile = null;
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
      this.iconImgFile = iconImgFile;
      this.iconImg = Image.file(iconImgFile);
    }
    else this.iconImg = Image.asset(Assets.DEFAULT_GAME);
  }


}

class GameSchemePrint {


  String gameName;



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


    while(dim.maxRow < row + 1) {addRow();}
    while(dim.maxCol < col + 1) {addColumn();}

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


class Challenge{



}