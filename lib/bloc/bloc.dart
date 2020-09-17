import 'dart:async';
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:firebase_database/firebase_database.dart';

import 'appstate_states.dart';
import 'auth_events.dart';
import 'auth_states.dart';

abstract class BlocEvent{}

abstract class Bloc{

  void mapEventToState(BlocEvent event);
  void dispose();
}

class BlocProvider
{
  static BlocProvider instance = BlocProvider._internal();
  factory BlocProvider() => instance;

  BlocProvider._internal(){
    dataBloc = new DataBloc();
  }

  DataBloc dataBloc;

}

class DataBloc extends Bloc {
  DataBloc() {
    authEventController.stream.asBroadcastStream().listen(mapEventToState);
    appStateEventController.stream.asBroadcastStream().listen((event) {mapEventToState(event);});
  }

  DataModel model = new DataModel();

  // AUTH
  final authEventController = StreamController<AuthEvent>();
  StreamSink<AuthEvent> get authEventSink => authEventController.sink;

  final authStateController = StreamController<AuthState>.broadcast();
  StreamSink<AuthState> get _authSink => authStateController.sink;
  Stream<AuthState> get authStream => authStateController.stream;


  // APP STATE
  final appStateEventController = StreamController<AppStateEvent>();
  StreamSink<AppStateEvent> get appStateEventSink => appStateEventController.sink;

  final appStateStateController = StreamController<AppStateState>.broadcast();
  StreamSink<AppStateState> get _appStateSink => appStateStateController.sink;
  Stream<AppStateState> get appStateStream => appStateStateController.stream;


  Future<void> mapEventToState(BlocEvent event) async {

    if (event is AuthEvent) {
        if(event is LoggingInEvent) {
          print('LoggingInEvent triggered');

          _authSink.add(LoggingInState(model));
          return;
        }

        if(event is LoginFailedEvent) {
          print('LoggingInEvent triggered');

          _authSink.add(LoginFailedState(model, event.msg));
          return;
        }

        if(event is SigningUpEvent) {
          print('SigningUpEvent triggered');

          _authSink.add(SigningUpState(model));
          return;
        }

        if(event is SignUpFailedEvent) {
          print('SignUpFailedEvent triggered');

          _authSink.add(SignUpFailedState(model, event.msg));
          return;
        }

        if(event is LogInEvent) {
          print('LogInEvent triggered');

          model.setUser(event.user);

          _authSink.add(LoggedInState(model));
          return;
        }

        if(event is LogOutEvent) {
          print('LogOutEvent triggered');

          model.setUser(null);

          _authSink.add(LogOutState(model));
          return;
        }

        if(event is ProfileComplete) {
          print('ProfileComplete triggered');
          _authSink.add(AuthState(model));
          return;
        }

        if(event is DeterminingProfileCompletionEvent)
        {
          print('DeterminingProfileCompletionEvent triggered');
          _authSink.add(DeterminingProfileCompletionState(model));
          return;
        }

        _authSink.add(AuthState(model));
      }


    if(event is AppStateEvent) {


      if(event is HelloUserEvent)
      {
        _appStateSink.add(AppStateState(model));
      }

      if(event is RefreshSchemesEditingAndOwned)
        {
          if(model.user.GetSchemeEditCodes() != null)
          {
            for(String code in model.user.GetSchemeEditCodes())
            {
              if(!model.hasSchemeMetaEditing(code))
              {
                SchemeMetadata schemeMeta = await NetworkServiceProvider.instance.netService.GetSchemeMetaFromCode(code);
                model.schemesEditing.add(schemeMeta);
              }
            }
          }

          if(model.user.GetSchemesOwnedCodes() != null) {
            for (String code in model.user.GetSchemesOwnedCodes()) {
              if (!model.hasSchemeMetaOwned(code)) {
                SchemeMetadata schemeMeta = await NetworkServiceProvider
                    .instance.netService.GetSchemeMetaFromCode(code);
                model.schemesOwned.add(schemeMeta);
              }
            }
          }
          _appStateSink.add(AppStateState(model));
        }

      if(event is SchemeEditorEvent) {
            if(event is StartNewSchemeEditEvent)
            {
              if(event.schemeMeta != null)
                {
                  GameScheme scheme = await NetworkServiceProvider.instance.netService.GetSchemeFromCode(event.schemeMeta.schemeID);
                  model.schemeEditorState.EditExistingScheme(scheme);
                }
              else if(event.info != null) {
                await model.schemeEditorState.EditNewScheme(event.info);
              }
                _appStateSink.add(AppStateState(model));

            }

            if(event is SchemeEditorCellPressedEvent)
            {
              model.schemeEditorState.TrySelectCell(event.gridSelection);
              _appStateSink.add(AppStateState(model));
            }

            if(event is SchemeEditorCellHeldEvent)
            {
              model.schemeEditorState.TrySelectCell(event.gridSelection);
              model.schemeEditorState.ToggleSwapMode();
              _appStateSink.add(AppStateState(model));
            }

            if(event is FighterAddedToSchemeEvent)
            {
              await model.schemeEditorState.AddFighterToSchemeInEditor(event.map, event.square);
              _appStateSink.add(AppStateState(model));
            }
            if(event is ToggleSwapModeEvent)
              {
                model.schemeEditorState.ToggleSwapMode();
                _appStateSink.add(AppStateState(model));
              }
            if(event is SwapSquaresEvent)
              {
                model.schemeEditorState.schemeInEditor.grid.Swap(model.schemeEditorState.schemeEditorGridSelection, event.gridRef);
                _appStateSink.add(AppStateState(model));
              }
            if(event is FighterEditedInSchemeEvent)
            {
              await model.schemeEditorState.EditFighter(event.fighter, event.map);
              _appStateSink.add(AppStateState(model));
            }

            if(event is SchemeEditorPageChanged)
            {
              model.schemeEditorState.schemeEditorPageNum = event.to;
              _appStateSink.add(AppStateState(model));
            }

            if(event is NewSchemeEditUploadedEvent)
              {
                model.UpdateOwnedSchemeEditsWithSchemeInEditor(event.schemeClone);


              }


        }

      if(event is SchemeEditLoadedEvent)
        {
//          model.schemesEditing.add(event.gs);
//
//          _appStateSink.add(AppStateState(model));
//          _userSink.add(UserState(model));
        }

      if(event is QueryForPublishedSchemes)
        {
          List<SchemeMetadata> list = await NetworkServiceProvider.instance.netService.QuerySchemes(event.queryInfo);

          model.EditQueriedSchemes(list, event.queryInfo.reset);

          _appStateSink.add(AppStateState(model));


        }

      if(event is SchemeDownloaded)
        {
          NetworkServices net = NetworkServiceProvider.instance.netService;
          await net.AddToOwnedSchemes(model.user, event.meta.schemeID);

          model.user.schemesOwned = await net.GetSchemeCodesOwned(model.user);

          _appStateSink.add(AppStateState(model));
        }

      if(event is RefreshFriendCodesAndChallengeCodes)
        {
          List<Future> futures = [];

          for(FriendListType type in FriendListType.values){
            futures.add(refreshFriendCodes(type));
          }

          futures.add(refreshChallengeCodes());

          await Future.wait(futures);

          _appStateSink.add(AppStateState(model));
        }

      if(event is ChangeSchemeEquipped)
        {
          model.schemeEquipped = event.smd;

          _appStateSink.add(AppStateState(model));
        }

      if(event is SubmitSearchForUserEvent)
        {
          _appStateSink.add(SearchingForUserState(model));

          // await GetUserMeta... TODO
          UserMetadata umd = await NetworkServiceProvider
              .instance.netService.GetUserMeta(event.userToSearch);

          _appStateSink.add(FinishedSearchForUserState(model, umd));
        }

      if(event is ChallengeUserEvent)
      {
        if(event.challengeInfo.schemeEquipped == null) return;
        // TODO Send failure event

        await NetworkServiceProvider.instance.netService.SendChallengeRequest(event.challengeInfo);
      }

      if(event is ChallengeStartedEvent)
      {
        model.challengeState.challengeInProgress = event.ch;
        model.challengeState.SetScheme(event.scheme);

        print('CHALLENGE STARTED: C received ' + event.ch.toJson().toString());
        _appStateSink.add(AppStateState(model));

      }

      if(event is FighterSelectedEvent)
        {
          if(event.fighterNum == null) return;

          if(model.challengeState.challengeInProgress.state == null)
            model.challengeState.challengeInProgress.state = new ChallengeStatus();

          // TODO A savvy data-saving way that doesn't dupe with local changes
          // Get current state and clone it, so we don't duplicate changes made
          // print('state at first: ' + model.challengeState.challengeInProgress.state.toJson().toString());
          // ChallengeStatus currentState = ChallengeStatus.fromJson(model.challengeState.challengeInProgress.state.toJson());
          //
          // print('state before: ' + currentState.toJson().toString());
          // currentState.SelectFighter(event.fighter, event.playerNum, event.fighterNum); // LOCAL WAY
          // print('state after: ' + currentState.toJson().toString());

          ChallengeStatus currentState = model.challengeState.challengeInProgress.state;
          print('state before: ' + currentState.toJson().toString());

          currentState.SelectFighter(event.fighter, event.playerNum, event.fighterNum);
          print('state after: ' + currentState.toJson().toString());

          String cid = model.challengeState.challengeInProgress.meta.challengeId;

          // Notify the rtd
          await NetworkServiceProvider.instance.netService.PushNewChallengeState(cid, currentState);

          _appStateSink.add(AppStateState(model));

        }

      if(event is ChallengeRequestChange)
      {
        if(event.snap == null || event.snap.value == null)
        {
          print('event.snap.value is NULL');
          return;
        }

        print("NEW CHALLENGE " + event.op.toString() + ' k: ' + event.snap.key.toString() + ' v: ' + event.snap.value.toString());
        // TODO Process change and refresh list, send state back to UI

        String challengeId = event.snap.key;
        Challenge challenge = await NetworkServiceProvider.instance.netService.GetChallengeFromCode(challengeId);

        // Map<String, dynamic> json = Map<String, dynamic>.from(event.snap.value);
        // Challenge challenge = Challenge.fromJson(json);

        if(event.op == Ops.add) {
          if(!model.hasChallenge(challenge.meta.challengeId)) model.AddChallenge(challenge);
        }
        if(event.op == Ops.remove) {
          if(model.hasChallenge(challenge.meta.challengeId)) model.RemoveChallenge(challenge.meta.challengeId);
        }

        _appStateSink.add(RefreshChallengeList(model, challenge, event.op));
      }

      if(event is FriendListChange)
      {
        if(event.snap == null || event.snap.value == null) return;

        print("NEW " + event.type.toString() + event.op.toString() + ' k: ' + event.snap.key.toString() + ' v: ' + event.snap.value.toString());
        // TODO Process change and refresh list, send state back to UI

        String friendId = event.snap.value;
        UserMetadata umd = await NetworkServiceProvider.instance.netService.GetUserMeta(friendId);
        UserMetadataWithKey umdwk = new UserMetadataWithKey(umd, event.snap.key);

        if(event.op == Ops.add) {
          if(!model.hasFriendMeta(friendId, event.type)) model.AddFriendMeta(umdwk, event.type);
        }
        if(event.op == Ops.remove) {
          if(model.hasFriendMeta(friendId, event.type)) model.RemoveFriendMeta(umdwk.userName, event.type);
        }

        _appStateSink.add(RefreshFriendsList(model, umdwk, event.op, event.type));

      }

      if(event is FriendRequestEvent)
      {
        // Inserts pointers into friendsPendingAcceptance and friendsRequests TODO
        await NetworkServiceProvider.instance.netService.SendFriendRequest(event.userMe, event.umd.userName);
      }

      if(event is ViewProfileEvent)
      {
        // Takes to full profile TODO
      }

      if(event is ChallengeStateChange)
        {
          ChallengeStatus newState = ChallengeStatus.fromJson(Map<String,dynamic>.from(event.snap.value));
          await model.challengeState.RefreshChallengeState(newState);
          _appStateSink.add(AppStateState(model));
        }

      if(event is FighterEntrySelectionEvent)
        {
          model.challengeState.ChangeEntrySelection(event.fighterNum);
          _appStateSink.add(AppStateState(model));
        }

      // Dev events
      if(event is ClearCacheEvent)
        {
          StorageManager.instance.ClearCache();
        }
    }
  }

@override
  void dispose()
  {
    authStateController.close();
    authEventController.close();
  }

  Future<void> refreshFriendCodes(FriendListType type) async {
    Map<String,String> map = model.user.GetFriendCodes(type);
    if(map != null)
    {
      for(String key in map.keys)
      {
        String userName = map[key];
        if(!model.hasFriendMeta(userName, type))
        {
          UserMetadata userMeta = await NetworkServiceProvider.instance.netService.GetUserMeta(userName);
          UserMetadataWithKey umdwk = new UserMetadataWithKey(userMeta, key);
          model.AddFriendMeta(umdwk, type);
        }
      }
    }
  }

  Future<void> refreshChallengeCodes() async {
    if(model.user.GetChallengeCodes() != null) {
      for (String code in model.user.GetChallengeCodes()) {
        if (!model.hasChallenge(code) && code != '') {
          Challenge challenge = await NetworkServiceProvider
              .instance.netService.GetChallengeFromCode(code);
          model.AddChallenge(challenge);
        }
      }
    }
  }

}







