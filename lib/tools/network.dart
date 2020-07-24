import 'dart:async';
import 'dart:io';

import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_events.dart';
import 'package:edojo/bloc/user_events.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/tools/Assets.dart';
import 'package:edojo/tools/storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class NetworkServiceProvider {
  NetworkServiceProvider._internal();

  static NetworkServiceProvider instance = NetworkServiceProvider._internal();

  factory NetworkServiceProvider() => instance;

  /// Declare the desired network service to be used.
  /// Options for user data: Firebase
  /// Options for game data: Firebase, MySQL, hosted SQL service (AWS?)
  NetworkServices netService = new AllFirebaseNetworkServices();
}

abstract class NetworkServices {

  // AUTH SERVICES //

  /// Fetch friend list for a given user
  Future<User> CreateUser(String email, String password);

  // Confirm a (unique) username and a (not unique, changeable) display name
  Future<void> CompleteProfile(User user, String userName, String displayName);

  /// Fetch sign in details
  Future<User> SignIn(String email, String password);

  /// Sign user out
  Future<void> SignOut();


  // INTER-USER SERVICES

  /// Send somebody a request to be your friend
  Future<void> SendFriendRequest(
      User userSendingRequest, String usernameOfRequestee);

  // Accept someones friend request
  Future<void> AcceptFriendRequest(
      User userAcceptingRequest, String usernameOfRequester);

  /// Send somebody a request for a challenge
  Future<void> SendChallengeRequest(
      User userSendingRequest, String usernameOfRequestee);

  /// Accept someones request for a challenge
  Future<void> AcceptChallengeRequest(
      User userAcceptingRequest, String usernameOfRequester);


  // SCHEME MANAGEMENT SERVICES

  Future<void> SaveSchemeToEdits(User user, GameScheme gameScheme);

  Future<void> UploadScheme(GameScheme gameScheme);

  Future<void> GetScheme(String schemeCode);

  /// Fetch friend list for a given user
  Future<List<User>> GetFriends(User user);

  /// Fetch scheme code list for a given user
  Future<List<String>> GetSchemeCodesOwned(User user);

  /// Fetch scheme for given code
  Future<GameScheme> GetSchemeFromCode(String schemeCode);

  Future<void> GetSchemeEdits(User user);

  Future<File> GetNetworkImage(String iconPath);

}

// TODO Make a network service that's solely (local) SQL
//class AllSQLNetworkServices extends NetworkServices;

//class FirebaseForUsersMySQLForGameDataNetworkServices extends NetworkServices;

/// Simplest network service extension that uses Google Firebase to manage all data
class AllFirebaseNetworkServices extends NetworkServices {

  // TODO Remove exception throwing from here, redirect to correspond to bloc states

  AllFirebaseNetworkServices(){

    //FirebaseApp.configure(name: null, options: null);

    this.authEventSink = BlocProvider.instance.dataBloc.authEventSink;
    this.userEventSink = BlocProvider.instance.dataBloc.userEventSink;
    this.appStateEventSink = BlocProvider.instance.dataBloc.appStateEventSink;
    FirebaseAuth.instance.onAuthStateChanged.asBroadcastStream().listen(_HandleAuthStateEvent);
  }

  String dbUrl = "https://edojo-9a273.firebaseio.com/";

  DatabaseReference dbRef = FirebaseDatabase.instance.reference();
  StorageReference storeRef = FirebaseStorage.instance.ref();

  FirebaseUser firebaseUser;
  StreamSink<AuthEvent> authEventSink;
  StreamSink<UserEvent> userEventSink;
  StreamSink<AppStateEvent> appStateEventSink;

  @override
  Future<User> CreateUser(String email, String password) async {

    AuthResult authResult;

    try {
      authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } catch (e, s) {
      print('$e $s');
      String msg = _GetFirebaseAuthException(e).toString();

      authEventSink.add(SignUpFailedEvent(msg));
    }

  }

  @override
  Future<void> CompleteProfile(
      User user, String username, String displayName) async {

    bool exists = await _CheckUserExists(username);
    if (exists) throw Exception('Username taken');

    // Set names
    user.SetNamesAndJoinDate(username, displayName, DateTime.now());

    // Make additions to the database: user object, name lookup
    Map<String, dynamic> updatesMap = {};

    updatesMap['users/${user.userName}'] = user.toJson();
    updatesMap['user_uids/${user.uid}'] = user.userName;

    try {
      await dbRef.update(updatesMap);
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }

    // Add display name to the user profile
    UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
    userUpdateInfo.displayName = displayName;
    await firebaseUser.updateProfile(userUpdateInfo);

    authEventSink.add(ProfileComplete());

  }

  @override
  Future<User> SignIn(String email, String password) async {

    authEventSink.add(LoggingInEvent());

    AuthResult authResult;
    try {
      authResult = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e, s) {
      print('$e $s');

      authEventSink.add(LoginFailedEvent(e.toString()));
      //throw _getFirebaseAuthException(e);
    }

  }

  /// Send somebody a request to be your friend
  @override
  Future<void> SendFriendRequest(
      User userSendingRequest, String usernameOfRequestee) async {
    bool exists = await _CheckUserExists(usernameOfRequestee);
    if (!exists) throw Exception('Couldn\'t find $usernameOfRequestee.');

    // Insert the necessary data
    Map<String, dynamic> updatesMap = {};
    String key = dbRef.push().key;

    updatesMap['users/${userSendingRequest.uid}/friendsPendingResponse/$key'] =
        userSendingRequest.userName;
    updatesMap['users/${usernameOfRequestee}/friendRequests/$key'] =
        userSendingRequest.userName;

    try {
      dbRef.update(updatesMap);
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }
  }

  // Accept someones friend request
  @override
  Future<void> AcceptFriendRequest(
      User userAcceptingRequest, String requestKey) async {
    DataSnapshot snap;

    try {
      snap = await dbRef
          .child(
              'users/${userAcceptingRequest.userName}/friendRequests/$requestKey')
          .once();
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }

    String requestersName = snap.value;

    // Insert the necessary data
    Map<String, dynamic> updatesMap = {};
    String key = dbRef.push().key;

    updatesMap['users/${requestersName}/friendsPendingResponse/$key'] = null;
    updatesMap['users/${userAcceptingRequest.userName}/friendRequests/$key'] =
        null;

    updatesMap['users/${requestersName}/friends/$key'] =
        userAcceptingRequest.userName;
    updatesMap['users/${userAcceptingRequest.userName}/friends/$key'] =
        requestersName;

    try {
      dbRef.update(updatesMap);
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }
  }

  /// Send somebody a request for a challenge
  @override
  Future<void> SendChallengeRequest(
      User userSendingRequest, String usernameOfRequestee) async {}

  /// Accept someones request for a challenge
  @override
  Future<void> AcceptChallengeRequest(
      User userAcceptingRequest, String usernameOfRequester) async {}

  @override
  Future<List<User>> GetFriends(User user) async {
    // Test
    DataSnapshot snap = await dbRef.child(user.uid).child('friends').once();
    print('(firebase) snap value as string: ' + snap.value.toString());

    var httpClient = new http.Client();
    var response = await httpClient.get(dbUrl + '/${user.uid}' + '/friends');

    print('(http) response as string: ' + response.body);

    return [];
  }

  @override
  Future<List<String>> GetSchemeCodesOwned(User user) {
    // TODO: implement getSchemeCodesOwned
    throw UnimplementedError();
  }

  @override
  Future<GameScheme> GetSchemeFromCode(String code) async {

    print('GetSchemeFromCode');

      DataSnapshot snap = await dbRef.child('schemeEdits/$code').once();

      Map<String,dynamic> map = Map<String,dynamic>.from(snap.value);
      GameScheme downloadedScheme = new GameScheme.fromJson(map);
      downloadedScheme.MakeGridFromUpload();

      Directory tempDir = await StorageManager.instance.GetTempDir();

      for(FighterScheme f in downloadedScheme.roster)
        {
          String iconImgId = f.iconImgId;
          if(iconImgId == null) continue;

          // Ratify images against cache and, if not there, add them
          String path = tempDir.path + '/icons/' + iconImgId + '.png';

          File file = File(path);
          if(!(await file.exists()))
            {
              print('$iconImgId does not exist, getting network image');
              file = await GetNetworkImage(iconImgId);
            }
          else
            {
              print('file $iconImgId exists');
            }

          f.iconImg = Image.file(file);
    }

      if(downloadedScheme.iconImgId != null)
        {
          String iconImgId = downloadedScheme.iconImgId;

          // Ratify images against cache and, if not there, add them
          String path = tempDir.path + '/icons/' + iconImgId + '.png';

          File file = File(path);
          if(!(await file.exists()))
          {
            print('$iconImgId does not exist, getting network image');
            file = await GetNetworkImage(iconImgId);
          }
          else
          {
            print('file $iconImgId exists');
          }

          downloadedScheme.iconImg = Image.file(file);
        }

      appStateEventSink.add(SchemeEditLoadedEvent(downloadedScheme));


  }
  
  @override
  Future<void> SignOut() {

    try
    {
      FirebaseAuth.instance.signOut();

    }catch(e, s)
    {
      print('$e $s');
    }
  }

  Exception _GetFirebaseAuthException(Exception error) {
    if (error is PlatformException) {
      switch (error.code) {
        case "ERROR_INVALID_EMAIL":
          return Exception("Your email address is in an invalid format.");
          break;
        case "ERROR_WRONG_PASSWORD":
          return Exception("Password incorrect.");
          break;
        case "ERROR_USER_NOT_FOUND":
          return Exception("User with this email doesn't exist.");
          break;
        case "ERROR_USER_DISABLED":
          return Exception("User with this email has been disabled.");
          break;
        case "ERROR_TOO_MANY_REQUESTS":
          return Exception("Too many requests. Try again later.");
          break;
        case "ERROR_OPERATION_NOT_ALLOWED":
          return Exception(
              "Signing in with Email and Password is not enabled.");
          break;
        default:
          return Exception("An undefined Error happened.");
      }
    } else
      return Exception('Error: ' + error.toString());
  }

  void _CheckDataSnapshot(DataSnapshot snap) {
    if (snap == null || snap.value == null)
      throw Exception('Error: Data not found.');
  }

  Future<FirebaseUser> _GetFirebaseUser() async {
    try {
      return await FirebaseAuth.instance.currentUser();
    } catch (e, s) {
      print('$e $s');
      throw _GetFirebaseAuthException(e);
    }
  }

  Future<bool> _CheckUserExists(String userName) async {
    DataSnapshot snap;

    try {
      snap = await dbRef.child('users/$userName/uid').once();
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }

    return (snap != null && snap.value != null);
  }

  Future<void> _HandleAuthStateEvent(FirebaseUser fUserEvent) async {

    print('handleAuthStateEvent triggered');

    // Case: Auth returns null user (is this possible?)
    if(fUserEvent == null)
      {
        if(firebaseUser != null) {
          firebaseUser = null;
        }
            authEventSink.add(LogOutEvent());
            return;
        }

    // Case: Auth event, but we already have a user TODO Deduce what's changed about this user
    if(firebaseUser != null) {
      firebaseUser = fUserEvent;
      authEventSink.add(AuthEvent()); // (1)
      return;
    }

    // Case: Auth event, and we have no user => Log in
    firebaseUser = fUserEvent;

    // Deduce stage in profile completion (is there registered username on rtd?)
    authEventSink.add(DeterminingProfileCompletionEvent());

    DataSnapshot snap = await dbRef.child('user_uids/${fUserEvent.uid}').once();
    if(snap != null)
      {
        if(snap.value == null) // Not created at all
          {
            print('User not registered at all state');
            authEventSink.add(LogInEvent(User.creation(fUserEvent.email, fUserEvent.uid))); // (1)
          }
        else // Has been fully created, return user
          {
            print('User registered state');

            snap = await dbRef.child('users/${snap.value}').once();
            print('handleAuthStateEvent: snap.value: '+snap.value.toString());

            if(snap != null && snap.value != null)
              {
                User user = User.fromJson(Map<String, dynamic>.from(snap.value));

                authEventSink.add(LogInEvent(user)); // (2)
                userEventSink.add(HelloUserEvent(user)); // (3)
                
                _SetListeners(user);
              }
            else
              {
                // TODO Do what?
              }


          }
      }

    // TODO More robust error handling




  }

  // LISTENERS
  void _SetListeners(User user) {

    // FRIENDS
    dbRef.child('users/${user.userName}/${User.FRIEND_REQUESTS}').onChildAdded.listen((event) { _HandleFriendRequestsChange(event, Ops.add); });
    dbRef.child('users/${user.userName}/${User.FRIEND_LIST}').onChildAdded.listen((event) { _HandleFriendListChange(event, Ops.add); });
    dbRef.child('users/${user.userName}/${User.FRIENDS_PENDING_RESPONSE}').onChildAdded.listen((event) { _HandleFriendListChange(event, Ops.add); });

    dbRef.child('users/${user.userName}/${User.FRIEND_REQUESTS}').onChildRemoved.listen((event) { _HandleFriendRequestsChange(event, Ops.remove); });
    dbRef.child('users/${user.userName}/${User.FRIEND_LIST}').onChildRemoved.listen((event) { _HandleFriendListChange(event, Ops.remove); });
    dbRef.child('users/${user.userName}/${User.FRIENDS_PENDING_RESPONSE}').onChildRemoved.listen((event) { _HandleFriendListChange(event, Ops.remove); });


    // CHALLENGES
    dbRef.child('users/${user.userName}/${User.CHALLENGE_REQUESTS}').onChildAdded.listen((event) { _HandleFriendRequestsChange(event, Ops.add); });

    dbRef.child('users/${user.userName}/${User.CHALLENGE_REQUESTS}').onChildRemoved.listen((event) { _HandleFriendRequestsChange(event, Ops.remove); });

  }

  void _HandleFriendRequestsChange(Event event, Ops op) {
    print('_HandleFriendRequestsChange called: event: ${event.snapshot.toString()}, op: ${op.toString()}');


  }

  void _HandleFriendListChange(Event event, Ops op) {
    print('_HandleFriendListChange called: event: ${event.snapshot.toString()}, op: ${op.toString()}');


  }

  void _RemoveListeners(User user)
  {
    // TODO Remove listeners
  }

  @override
  Future<void> GetScheme(String schemeCode) {
    // TODO: implement GetScheme
    throw UnimplementedError();
  }

  @override
  Future<void> UploadScheme(Object args) {
    // TODO: implement UploadScheme
    throw UnimplementedError();
  }


  @override
  Future<void> SaveSchemeToEdits(User user, GameScheme gameScheme) async {
    appStateEventSink.add(NewSchemeEditUploadingEvent());

    try {
      GameScheme schemeClone = GameScheme.jsonClone(gameScheme);
      schemeClone.ClearVarsForUpload();

      Directory tempDir = StorageManager.instance.appDir == null ? await StorageManager.instance.GetTempDir() : StorageManager.instance.appDir;
      String tempPath = tempDir.path;
      //Map<String,File> toUpload = {};

      for (FighterScheme f in schemeClone.roster) {

        String iconImgId = f.iconImgId;
        if (iconImgId == null) continue;

        String cloudPath = 'icons/' + iconImgId + '.png';
        File file = File(tempPath + '/icons/' + iconImgId + '.png');

        storeRef.child(cloudPath).putFile(file);

        // TODO Optimise this shit

      }

      if (gameScheme.iconImgId != null) {

        String iconImgId = gameScheme.iconImgId;
        if (iconImgId != null)
          {
            String cloudPath = 'icons/' + iconImgId + '.png';

            File file = File(tempPath + '/icons/' + iconImgId + '.png');
            storeRef.child(cloudPath).putFile(file);
          }
      }

      Map<String, dynamic> updates = {};
      String key;

      if(schemeClone.schemeID != null) key = schemeClone.schemeID;
      else {
        key = dbRef.push().key;
        schemeClone.schemeID = key;
        gameScheme.schemeID = key;

        updates.addAll({ 'users/${user.userName}/${User.SCHEMES_IN_EDITOR}/$key' : '' });
      }

        updates.addAll({ 'schemeEdits/$key' : schemeClone.toJson() });

        print(schemeClone.toJson());
        await dbRef.update(updates);

        // Add local changes
        appStateEventSink.add(NewSchemeEditUploadedEvent(schemeClone));

      //Map<String, dynamic> json = gameScheme.toJson();

    }catch(e, s){
      print('$e $s');
    }


  }

  @override
  Future<void> GetSchemeEdits(User user) async {

    
  }

  @override
  Future<File> GetNetworkImage(String iconImgId) async {

    try
    {
      print('GetNetworkImage path: $iconImgId');

        Directory systemTempDir = await StorageManager.instance.GetTempDir();

        String path = systemTempDir.path + '/icons/' + iconImgId + '.png';

      print('GetNetworkImage creating local path: $path');

        File file = await File(path).create(recursive: true);
        storeRef.child('icons/$iconImgId.png').writeToFile(file);

        return file;
    }
    catch(e)
    {
      print('GetNetworkImage error: ' + e.toString());
      return null;
    }



    // TODO Optimise this shit
  }


}


enum Ops{
  add, remove
}


