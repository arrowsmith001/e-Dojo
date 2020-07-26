import 'dart:async';
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/user_events.dart';
import 'package:edojo/bloc/user_states.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/tools/network.dart';

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
    userEventController.stream.asBroadcastStream().listen(mapEventToState);
    appStateEventController.stream.asBroadcastStream().listen((event) {mapEventToState(event);});
  }

  DataModel model = new DataModel();

  // AUTH
  final authEventController = StreamController<AuthEvent>();
  StreamSink<AuthEvent> get authEventSink => authEventController.sink;

  final authStateController = StreamController<AuthState>.broadcast();
  StreamSink<AuthState> get _authSink => authStateController.sink;
  Stream<AuthState> get authStream => authStateController.stream;


  // USER
  final userEventController = StreamController<UserEvent>();
  StreamSink<UserEvent> get userEventSink => userEventController.sink;

  final userStateController = StreamController<UserState>.broadcast();
  StreamSink<UserState> get _userSink => userStateController.sink;
  Stream<UserState> get userStream => userStateController.stream;


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

    if(event is UserEvent){

      if(event is HelloUserEvent)
        {


          _userSink.add(HelloUserState(model));
        }

      if(event is FriendListEvent)
        {




        }


    }

    if(event is AppStateEvent) {

      if(event is SchemePageReachedEvent)
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
            _userSink.add(UserState(model));
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
              model.schemeEditorState.ToggleSwapMode(event.gridSelection);
              _appStateSink.add(AppStateState(model));
            }

            if(event is FighterAddedToSchemeEvent)
            {
              await model.schemeEditorState.AddFighterToSchemeInEditor(event.map);
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
    }
  }

@override
  void dispose()
  {
    authStateController.close();
    authEventController.close();
  }

}



