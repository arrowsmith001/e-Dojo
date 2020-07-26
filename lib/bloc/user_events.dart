import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/classes/misc.dart';

class UserEvent extends BlocEvent
{

}


class HelloUserEvent extends UserEvent{
  HelloUserEvent(this.user);

  User user;
}

class FriendListEvent extends UserEvent{
  FriendListEvent(this.friendList);

  List<User> friendList;

}

class SchemeEditsEvent extends UserEvent{
  SchemeEditsEvent(this.schemesInEditor);

  List<SchemeMetadata> schemesInEditor;

}