import 'dart:io';

import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/pages/_challenges.dart';
import 'package:edojo/pages/_schemes.dart';
import 'package:edojo/tools/network.dart';
import 'package:firebase_database/firebase_database.dart';

class AppStateEvent extends BlocEvent{}

class SchemeEditorEvent extends AppStateEvent{}

class HelloUserEvent extends AppStateEvent{
  HelloUserEvent(this.user);

  User user;
}

class FriendListEvent extends AppStateEvent{
  FriendListEvent(this.friendList);

  List<User> friendList;

}

class SchemeEditsEvent extends AppStateEvent{
  SchemeEditsEvent(this.schemesInEditor);

  List<SchemeMetadata> schemesInEditor;

}

class StartNewSchemeEditEvent extends SchemeEditorEvent{
  NewGameInfo info;
  SchemeMetadata schemeMeta;

  StartNewSchemeEditEvent(this.info);
  StartNewSchemeEditEvent.resume(this.schemeMeta);
}
class SchemeEditorCellPressedEvent extends SchemeEditorEvent{
  SchemeEditorCellPressedEvent(this.gridSelection);
  GridSelection gridSelection;

}
class SchemeEditorCellHeldEvent extends SchemeEditorEvent{
  SchemeEditorCellHeldEvent(this.gridSelection);
  GridSelection gridSelection;

}
class FighterAddedToSchemeEvent extends SchemeEditorEvent {
  FighterAddedToSchemeEvent(this.map, this.square);
  Map<String,dynamic> map;
  Square square;
 // File iconFile;

}
class SwapSquaresEvent extends SchemeEditorEvent {
  SwapSquaresEvent(this.gridRef);
  GridSelection gridRef;
}
class ToggleSwapModeEvent extends SchemeEditorEvent {}
class SchemeEditorPageChanged extends SchemeEditorEvent {
  SchemeEditorPageChanged(this.to);
  int to;
}
class FighterEditedInSchemeEvent extends SchemeEditorEvent {
  FighterEditedInSchemeEvent(this.fighter, this.map);
  FighterScheme fighter;
  Map<String,dynamic> map;
}
class NewSchemeEditUploadingEvent extends SchemeEditorEvent{}
class NewSchemeEditUploadedEvent extends SchemeEditorEvent{
  NewSchemeEditUploadedEvent(this.schemeClone);
  GameScheme schemeClone;
}


class RefreshSchemesEditingAndOwned extends AppStateEvent{}
class SchemeEditLoadedEvent extends AppStateEvent{
  SchemeEditLoadedEvent(this.gs);
  GameScheme gs;
}

class RefreshFriendCodesAndChallengeCodes extends AppStateEvent{}


class QueryForPublishedSchemes extends AppStateEvent {
  QueryForPublishedSchemes(this.queryInfo);
  SchemeQueryInfo queryInfo;
}

class SchemeDownloaded extends AppStateEvent {
  SchemeDownloaded(this.meta);
  SchemeMetadata meta;
}

class ChangeSchemeEquipped extends AppStateEvent {
  ChangeSchemeEquipped(this.smd);
  SchemeMetadata smd;
}

class SubmitSearchForUserEvent extends AppStateEvent {
  SubmitSearchForUserEvent(this.userToSearch);
  String userToSearch;
}

class ChallengeUserEvent extends AppStateEvent{
  ChallengeUserEvent(this.challengeInfo);
  ChallengeInfo challengeInfo;
}


class FriendRequestEvent extends AppStateEvent{
  FriendRequestEvent(this.umd, this.userMe);
  UserMetadata umd;
  User userMe;
}

class ViewProfileEvent extends AppStateEvent {
  ViewProfileEvent(this.umd);
  UserMetadata umd;
}

class ChallengeStartedEvent extends AppStateEvent {
  ChallengeStartedEvent(this.ch, this.scheme);
  final Challenge ch;
  final GameScheme scheme;
}
class ChallengeEndedEvent extends AppStateEvent {
  ChallengeEndedEvent(this.ch);
  final Challenge ch;
}
class ChallengeExitedEvent extends AppStateEvent {
  ChallengeExitedEvent(this.ch);
  final Challenge ch;
}

class FighterSelectedEvent extends AppStateEvent {
  FighterSelectedEvent(this.fighter, this.varString, this.playerNum, this.fighterNum);
  final FighterScheme fighter;
  final String varString;
  final int playerNum;
  final int fighterNum;
}
class FighterUnselectedEvent extends AppStateEvent {
  FighterUnselectedEvent(this.fighter, this.playerNum);
  FighterScheme fighter;
  final int playerNum;
}
class FighterEntrySelectionEvent extends AppStateEvent {
  FighterEntrySelectionEvent(this.fighterNum);
  int fighterNum;
}

// Firebase callbacks to user changes

class ChallengeRequestChange extends AppStateEvent{
  DataSnapshot snap;
  Ops op;
  ChallengeRequestChange(this.snap, this.op);
}

class FriendListChange extends AppStateEvent{
  DataSnapshot snap;
  Ops op;
  FriendListType type;
  FriendListChange(this.snap, this.op, this.type);
}

class ChallengeStateChange extends AppStateEvent {
  DataSnapshot snap;
  ChallengeStateChange(this.snap);
}

class ToggleReadyEvent extends AppStateEvent {
  ToggleReadyEvent(this.pNum,this.to);
  int pNum;
  bool to;

}

// Dev events
class ClearCacheEvent extends AppStateEvent {

}
