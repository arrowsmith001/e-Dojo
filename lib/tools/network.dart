import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_events.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/pages/_challenges.dart';
import 'package:edojo/pages/_schemes.dart';
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
  Future<void> SendChallengeRequest(ChallengeInfo challengeInfo);

  /// Accept someones request for a challenge
  Future<void> AcceptChallengeRequest(
      User userAcceptingRequest, String usernameOfRequester);


  // SCHEME MANAGEMENT SERVICES

  Future<void> SaveSchemeToEdits(User user, GameScheme gameScheme);

  Future<void> UploadScheme(User user, GameScheme gameScheme);

  /// Fetch scheme metadata for a given scheme code
  Future<SchemeMetadata> GetSchemeMetaFromCode(String schemeCode);

  /// Fetch friend list for a given user
  Future<List<User>> GetFriends(User user);

  /// Fetch scheme code list for a given user
  Future<Map<String,String>> GetSchemeCodesOwned(User user);

  /// Fetch scheme for given code
  Future<GameScheme> GetSchemeFromCode(String schemeCode);

  Future<void> GetSchemeEdits(User user);

  Future<File> GetNetworkImage(String iconPath);

  Future<List<SchemeMetadata>> QuerySchemes(SchemeQueryInfo queryInfo);

  Future<void> AddToOwnedSchemes(User user, String schemeCode);

  Future<UserMetadata> GetUserMeta(String userName);

  Future<Challenge> GetChallengeFromCode(String code);

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
    this.appStateEventSink = BlocProvider.instance.dataBloc.appStateEventSink;
    FirebaseAuth.instance.onAuthStateChanged.asBroadcastStream().listen(_HandleAuthStateEvent);
  }

  String dbUrl = "https://edojo-9a273.firebaseio.com/";

  DatabaseReference dbRef = FirebaseDatabase.instance.reference();
  StorageReference storeRef = FirebaseStorage.instance.ref();
  Firestore firestoreRef = Firestore.instance;

  FirebaseUser firebaseUser;
  StreamSink<AuthEvent> authEventSink;
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

    updatesMap['users/${user.meta.userName}'] = user.toJson();
    updatesMap['user_uids/${user.meta.uid}'] = user.meta.userName;

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

    updatesMap['users/${userSendingRequest.meta.userName}/friendsPendingResponse/$key'] =
        usernameOfRequestee;
    updatesMap['users/${usernameOfRequestee}/friendRequests/$key'] =
        userSendingRequest.meta.userName;

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
              'users/${userAcceptingRequest.meta.userName}/friendRequests/$requestKey')
          .once();
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }

    String requestersName = snap.value;

    // Insert the necessary data
    Map<String, dynamic> updatesMap = {};
    String key = dbRef.push().key;

    updatesMap['users/${requestersName}/${User.FRIENDS_PENDING_RESPONSE}/$requestKey'] = null;
    updatesMap['users/${userAcceptingRequest.meta.userName}/${User.FRIEND_REQUESTS}/$requestKey'] = null;

    updatesMap['users/${requestersName}/${User.FRIEND_LIST}/$key'] = userAcceptingRequest.meta.userName;
    updatesMap['users/${userAcceptingRequest.meta.userName}/${User.FRIEND_LIST}/$key'] = requestersName;

    try {
      await dbRef.update(updatesMap);
    } catch (e, s) {
      print('$e $s');
      rethrow;
    }
  }

  /// Send somebody a request for a challenge
  @override
  Future<void> SendChallengeRequest(ChallengeInfo info) async {

    // TODO Code to send a challenge (adding it to RTD), have challenge appear on challenges pending response, for self as well as other participant

    String challengeRequestKey = dbRef.push().key;
    Challenge challenge = Challenge.fromInfo(info, challengeRequestKey);

    Map<String,dynamic> updates = {};

    updates.addAll({'challenges/$challengeRequestKey' : challenge.toJson()});
    updates.addAll({'users/' + challenge.player1.userName + '/' + User.CHALLENGE_REQUESTS + '/' + challengeRequestKey : ''});
    updates.addAll({'users/' + challenge.player2.userName + '/' + User.CHALLENGE_REQUESTS + '/' + challengeRequestKey : ''});

    await dbRef.update(updates);
  }

  /// Accept someones request for a challenge
  @override
  Future<void> AcceptChallengeRequest(
      User userAcceptingRequest, String usernameOfRequester) async {}

  @override
  Future<List<User>> GetFriends(User user) async {
    // Test
    DataSnapshot snap = await dbRef.child('users').child(user.meta.userName).child('friends').once();
    print('(firebase) snap value as string: ' + snap.value.toString());

    // TODO

//    var httpClient = new http.Client();
//    var response = await httpClient.get(dbUrl + '/${user.uid}' + '/friends');

//    print('(http) response as string: ' + response.body);

    return [];
  }

  @override
  Future<Map<String,String>> GetSchemeCodesOwned(User user) async {
    DataSnapshot snap = await dbRef.child('users/${user.meta.userName}/${User.SCHEMES_OWNED}').once();
    return snap == null ? null : Map<String,String>.from(snap.value);
  }

  @override
  Future<SchemeMetadata> GetSchemeMetaFromCode(String code) async {

    print('GetSchemeMetaFromCode');

    DataSnapshot snap = await dbRef.child('schemes/$code/meta').once();

    Map<String,dynamic> map = Map<String,dynamic>.from(snap.value);
    SchemeMetadata downloadedMeta = new SchemeMetadata.fromJson(map);

    Directory tempDir = await StorageManager.instance.GetTempDir();

    if(downloadedMeta.iconImgId != null)
    {
      String iconImgId = downloadedMeta.iconImgId;

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

      downloadedMeta.iconImg = Image.file(file);
    }

    return downloadedMeta;
  }

  @override
  Future<GameScheme> GetSchemeFromCode(String code) async {

    print('GetSchemeFromCode');

      DataSnapshot snap = await dbRef.child('schemes/$code').once();

      Map<String,dynamic> map = Map<String,dynamic>.from(snap.value);
      GameScheme downloadedScheme = new GameScheme.fromJson(map);
      downloadedScheme.MakeGridFromUpload();

      Directory tempDir = await StorageManager.instance.GetTempDir();

      for(FighterScheme f in downloadedScheme.roster)
        {
          String iconImgId = f.iconImgId;
          if(iconImgId == null) continue;

          File file = await _ReturnNetworkImageFileOrCachedIfExists(iconImgId, tempDir);

          f.iconImg = Image.file(file);
    }

      if(downloadedScheme.meta.iconImgId != null)
        {
          String iconImgId = downloadedScheme.meta.iconImgId;

          File file = await _ReturnNetworkImageFileOrCachedIfExists(iconImgId, tempDir);

          downloadedScheme.meta.iconImg = Image.file(file);
        }

      return downloadedScheme;
      //appStateEventSink.add(SchemeEditLoadedEvent(downloadedScheme));


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
      snap = await dbRef.child('users/$userName/meta/uid').once();
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
            authEventSink.add(LogInEvent(User.init(new UserMetadata.basic(fUserEvent.email, fUserEvent.uid)))); // (1)
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
                appStateEventSink.add(HelloUserEvent(user)); // (3)
                
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

    // TODO Remove listeners when finished

    // FRIENDS
    dbRef.child('users/${user.meta.userName}/${User.FRIEND_REQUESTS}').onChildAdded.listen((event) { _HandleFriendRequestsChange(event, Ops.add); });
    dbRef.child('users/${user.meta.userName}/${User.FRIEND_LIST}').onChildAdded.listen((event) { _HandleFriendListChange(event, Ops.add); });
    dbRef.child('users/${user.meta.userName}/${User.FRIENDS_PENDING_RESPONSE}').onChildAdded.listen((event) { _HandleFriendsPendingChange(event, Ops.add); });

    dbRef.child('users/${user.meta.userName}/${User.FRIEND_REQUESTS}').onChildRemoved.listen((event) { _HandleFriendRequestsChange(event, Ops.remove); });
    dbRef.child('users/${user.meta.userName}/${User.FRIEND_LIST}').onChildRemoved.listen((event) { _HandleFriendListChange(event, Ops.remove); });
    dbRef.child('users/${user.meta.userName}/${User.FRIENDS_PENDING_RESPONSE}').onChildRemoved.listen((event) { _HandleFriendsPendingChange(event, Ops.remove); });

    // CHALLENGES
    dbRef.child('users/${user.meta.userName}/${User.CHALLENGE_REQUESTS}').onChildAdded.listen((event) { _HandleChallengeRequestsChange(event, Ops.add); });
    dbRef.child('users/${user.meta.userName}/${User.CHALLENGE_REQUESTS}').onChildRemoved.listen((event) { _HandleChallengeRequestsChange(event, Ops.remove); });

  }

  void _HandleFriendListChange(Event event, Ops op) {
    print('_HandleFriendListChange called: event: ${event.snapshot.toString()}, op: ${op.toString()}');
    appStateEventSink.add(FriendListChange(event.snapshot, op, FriendListType.FullFriends));
  }

  void _HandleFriendRequestsChange(Event event, Ops op) {
    print('_HandleFriendRequestsChange called: event: ${event.snapshot.toString()}, op: ${op.toString()}');
    appStateEventSink.add(FriendListChange(event.snapshot, op, FriendListType.FriendRequests));
  }

  void _HandleFriendsPendingChange(Event event, Ops op) {
    print('_HandleFriendRequestsChange called: event: ${event.snapshot.toString()}, op: ${op.toString()}');
    appStateEventSink.add(FriendListChange(event.snapshot, op, FriendListType.FriendsPending));
  }

  void _HandleChallengeRequestsChange(Event event, Ops op){
    print('_HandleChallengeRequestsChange called: event: ${event.snapshot.value.toString()}, op: ${op.toString()}');
    appStateEventSink.add(ChallengeRequestChange(event.snapshot, op));
  }

  void _RemoveListeners(User user)
  {
    // TODO Remove listeners
  }

  @override
  Future<GameScheme> GetScheme(String schemeCode) {
    // TODO: implement GetScheme
    throw UnimplementedError();
  }

  @override
  Future<void> UploadScheme(User user, GameScheme gameScheme) async {

    Map<String,dynamic> schemeMetaMap = gameScheme.meta.GetMap();

    QuerySnapshot qs = await firestoreRef.collection('publishedSchemes').where('databaseRef', isEqualTo: gameScheme.meta.schemeID).getDocuments();

    if(qs.documents == null || qs.documents.length == 0) // Non-existent entry
      {
      await firestoreRef.collection('publishedSchemes').add(schemeMetaMap);
      }
    else
      {
        String docId = qs.documents[0].documentID;
        await firestoreRef.document(docId).updateData(schemeMetaMap);
      }


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

        // TODO Optimise this shit (no need to re-upload if upload exists already)

      }

      if (gameScheme.meta.iconImgId != null) {

        String iconImgId = gameScheme.meta.iconImgId;
        if (iconImgId != null)
          {
            String cloudPath = 'icons/' + iconImgId + '.png';

            File file = File(tempPath + '/icons/' + iconImgId + '.png');
            storeRef.child(cloudPath).putFile(file);
          }
      }

      Map<String, dynamic> updates = {};
      String key;

      if(schemeClone.meta.schemeID != null) key = schemeClone.meta.schemeID;
      else {
        key = dbRef.push().key;
        schemeClone.meta.schemeID = key;
        gameScheme.meta.schemeID = key;

        updates.addAll({ 'users/${user.meta.userName}/${User.SCHEMES_IN_EDITOR}/$key' : '' });
      }

        updates.addAll({ 'schemes/$key' : schemeClone.toJson() });

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

  @override
  Future<List<SchemeMetadata>> QuerySchemes(SchemeQueryInfo queryInfo) async {

    QuerySnapshot qs = await firestoreRef.collection('publishedSchemes')
        .orderBy(queryInfo.orderBy, descending: queryInfo.descending)
        .limit(queryInfo.numberOfDocuments)
        .getDocuments();

    Directory tempDir = await getTemporaryDirectory();

    List<SchemeMetadata> out = [];

    for(DocumentSnapshot doc in qs.documents)
      {
        String schemeId = doc['databaseRef'];
        String name = doc['name'];
        String nickname = doc['nickname'];
        String iconImgId = doc['iconRef'];
        int upvotes = doc['upvotes'];

        File imgFile;
        if(iconImgId != null && iconImgId != '') imgFile = await _ReturnNetworkImageFileOrCachedIfExists(iconImgId, tempDir);

        out.add(new SchemeMetadata.fromQuery(schemeId, name, nickname, iconImgId, imgFile, upvotes));
      }

    return out;

  }

  Future<File> _ReturnNetworkImageFileOrCachedIfExists(String iconImgId, Directory tempDir) async {

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

    return file;
  }

  @override
  Future<void> AddToOwnedSchemes(User user, String schemeCode) async {
    String userName = user.meta.userName;

    dbRef.child('users/$userName/${User.SCHEMES_OWNED}/$schemeCode').set('');

  }

  @override
  Future<UserMetadata> GetUserMeta(String userName) async {

    DataSnapshot snap = await dbRef.child('users').child(userName).child('meta').once();
    if(snap == null || snap.value == null) return null;

    UserMetadata userMeta = UserMetadata.fromJson(Map<String,dynamic>.from(snap.value));
    return userMeta;
  }

  @override
  Future<Challenge> GetChallengeFromCode(String code) async {
    DataSnapshot snap = await dbRef.child('challenges/$code').once();
    Challenge ch = Challenge.fromJson(Map<String,dynamic>.from(snap.value));

    // Get scheme elements
    File schemeIcon = await GetNetworkImage(ch.schemeImgId);
    Image schemeImg = Image.file(schemeIcon);

    ch.schemeImgFile = schemeIcon;
    ch.schemeImg = schemeImg;

    // Get user elements TODO Optimise
    ch.player1 = await GetUserMeta(ch.player1Username);
    ch.player2 = await GetUserMeta(ch.player2Username);

    return ch;
  }




}






enum Ops{
  add, remove
}




