import 'dart:io';

import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/pages/schemes.dart';

class AppStateEvent extends BlocEvent{}

class SchemeEditorEvent extends AppStateEvent{}

class StartNewSchemeEditEvent extends SchemeEditorEvent{
  NewGameInfo info;
  GameScheme scheme;

  StartNewSchemeEditEvent(this.info);
  StartNewSchemeEditEvent.resume(this.scheme);
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
  FighterAddedToSchemeEvent(this.map);
  Map<String,dynamic> map;

}
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


class SchemePageReachedEvent extends AppStateEvent{}
class SchemeEditLoadedEvent extends AppStateEvent{
  SchemeEditLoadedEvent(this.gs);
  GameScheme gs;
}