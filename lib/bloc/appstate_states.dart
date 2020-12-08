
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/tools/network.dart';

class AppStateState{
  DataModel model;
  AppStateState(this.model);

}

class SearchingForUserState extends AppStateState {
  SearchingForUserState(DataModel model) : super(model);
}
class FinishedSearchForUserState extends AppStateState {
  FinishedSearchForUserState(DataModel model, this.umd) : super(model);
  UserMetadata umd;
}

class RefreshFriendsList extends AppStateState {
  UserMetadataWithKey umdwk;
  Ops op;
  FriendListType type;
  RefreshFriendsList(DataModel model, this.umdwk, this.op, this.type) : super(model);
}

class RefreshChallengeList extends AppStateState {
  Challenge newChallenge;
  Ops op;
  RefreshChallengeList(DataModel model, this.newChallenge, this.op) : super(model);
}

class ChallengeStartedState extends AppStateState {
  ChallengeStartedState(DataModel model) : super(model);
}