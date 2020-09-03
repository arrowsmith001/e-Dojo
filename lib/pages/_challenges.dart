import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/appstate_states.dart';
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/main.dart';
import 'package:edojo/tools/assets.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/widgets/my_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:edojo/widgets/extensions.dart';
import 'package:flutter/scheduler.dart';

class ChallengesPage extends StatefulWidget {
  @override
  _ChallengesPageState createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin{

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  TabController _tabController;
  TextEditingController _textEditController;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    data.appStateEventSink.add(RefreshSchemesEditingAndOwned());
    data.appStateEventSink.add(RefreshFriendCodesAndChallengeCodes());

    _tabController = TabController(vsync: this, length: 2);
    _textEditController = TextEditingController();
    _scrollController = ScrollController();

  }

  bool isDialogShowing = false;

  void showLoadingDialog(BuildContext context, String msg)
  {
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(margin: EdgeInsets.only(left: 2),child:Text(msg)),
        ],).MY_BACKGROUND_CONTAINER(),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      isDialogShowing = true;
      showDialog(context: context, builder: (context) => alert, barrierDismissible: false);
    });
  }

  void showUserSearchResultDialog(UserMetadata umd, User userMe, DataModel dm) {
    AlertDialog alert = AlertDialog(
      content: umd == null ? Text('User not found.').MY_BACKGROUND_CONTAINER()
        : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              child: Column(
                children: [
                  Text(umd.displayName),
                  Text(umd.userName),
                  FlatButton(child: Text('CHALLENGE ' + umd.displayName.toUpperCase(), style: TextStyle(color: Colors.white),), onPressed: () { challengeUser(umd, userMe, dm.schemeEquipped); }),
                  FlatButton(child: Text('ADD ' + umd.displayName.toUpperCase() + ' TO FRIENDS', style: TextStyle(color: Colors.white)), onPressed: () { addToFriends(umd, userMe); },),
                  FlatButton(child: Text('VIEW ' + umd.displayName.toUpperCase() + '\'S PROFILE', style: TextStyle(color: Colors.white)), onPressed: () { viewProfile(umd); },),
                ],
              ),
              margin: EdgeInsets.only(left: 2)),
        ]).MY_BACKGROUND_CONTAINER(),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      isDialogShowing = true;
      showDialog(context: context, builder: (context) => alert, barrierDismissible: true);
    });
  }

  void dismissDialog(BuildContext context) {
    if(isDialogShowing) Navigator.of(context).pop();
    isDialogShowing = false;
  }

  void challengeUser(UserMetadata umd, User userMe, SchemeMetadata schemeEquipped) {
    dismissDialog(context);
    data.appStateEventSink.add(ChallengeUserEvent(new ChallengeInfo(umd, userMe, schemeEquipped)));
  }

  void addToFriends(UserMetadata umd, User userMe) {
    data.appStateEventSink.add(FriendRequestEvent(umd, userMe));
  }

  void viewProfile(UserMetadata umd) {
    dismissDialog(context);
    data.appStateEventSink.add(ViewProfileEvent(umd));
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AppStateState>(
        stream: data.appStateStream,
        initialData: AppStateState(data.model),
        builder: (context, snapshot) {

          AppStateState ds = snapshot.data;
          DataModel dm = ds.model;
          User user = dm.user;
          List<SchemeMetadata> schemesOwnedList = dm.schemesOwned;
          SchemeMetadata schemeEquipped = dm.schemeEquipped;

          Challenge challengeInProgress = dm.challengeState.challengeInProgress;

          List<UserMetadata> friendsList = dm.friendsList;
          List<UserMetadata> friendRequests = dm.friendRequests;
          List<UserMetadata> friendsPending = dm.friendsPending;
          List<Challenge> challengersList = dm.challengesList;

          if(ds is SearchingForUserState){
            showLoadingDialog(context, 'Searching...');
          }

          if(ds is FinishedSearchForUserState){
            if(isDialogShowing) dismissDialog(context);
            showUserSearchResultDialog(ds.umd, user, dm);
          }

          if(ds is RefreshChallengeList)
          {
            if(ds.op == Ops.add)
            {
              print("NEW CHALLENGE ACKNOWLEDGED");
            }
          }

          if(ds is RefreshFriendsList)
          {
            print('RefreshFriendsList: ' + ds.type.toString() + ' ' + ds.op.toString() + ' ' + ds.umdwk.userName);
          }


          return Scaffold(
            appBar:
            MyAppbar(
              title: Text('Challenges', style: TextStyle(color: Colors.white),),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("PLAYING: ", textAlign: TextAlign.left,),
                      Container(
                          child: DropdownButton<SchemeMetadata>(
                            value: schemeEquipped,
                              onChanged: (smd) {
                              print('Changed to '+smd.gameName);
                                data.appStateEventSink.add(ChangeSchemeEquipped(smd));
                              },
                              items: schemesOwnedList.map((SchemeMetadata smd)
                              {
                                return DropdownMenuItem<SchemeMetadata>(
                                  value: smd,
                                    child: Container(
                                        child: Text(smd.gameName),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 2, color: Colors.blue),
                                            borderRadius: BorderRadius.all(Radius.circular(15)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withAlpha(70),
                                                blurRadius: 50.0,
                                                spreadRadius: 10.0,
                                                offset: Offset(0.0, 0.0,
                                                ),
                                              ),
                                            ]
                                        )));
                              }).toList()

                          )
                      )
                    ],
                  ).padding(EdgeInsets.symmetric(horizontal: 16.0)).EXPANDED()],
                ),
              ),
            ),
            body: SafeArea(
            //  child: Center(

                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [

                    // CHALLENGES/FRIENDS TABVIEW
                    TabBar(
                      controller: _tabController,
                      tabs: <Widget>[
                        Tab(child: Text('CHALLENGES',  style: TextStyle(color: Colors.white)),),
                        Tab(child: Text('FRIENDS',  style: TextStyle(color: Colors.white)),),
                      ],).FLEX(0),

                    TabBarView(
                      controller: _tabController,
                      children: [

                        challengersList.isEmpty ? Center(
                            child:
                            Text('You have no pending challenges', style: TextStyle(color: Colors.white),).padding(EdgeInsets.symmetric(vertical: 16, horizontal: 16))
                        )
                            : ListView.builder(
                            shrinkWrap: true,
                            itemCount: challengersList.length,
                            itemBuilder: (context, i) {

                              Challenge ch = challengersList[i];

                              String schemeName = ch.schemeName;
                              String p1name = ch.player1Username;
                              String p2name = ch.player2Username;

                              Image schemeImg = ch.schemeImg;

                              Image p1Img = ch.player1.GetImage();
                              Image p2Img = ch.player2.GetImage();

                              bool isChallenger = p1name == user.meta.userName;
                              String text = isChallenger ? 'You challenged ' + p2name + ' to ' + schemeName
                                  : p1name + ' challenged you to ' + schemeName;

                              return Row(
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(children: [
                                        p1Img.SIZED(width: 40).padding(EdgeInsets.all(5)),
                                        Text('vs'),
                                        p2Img.SIZED(width: 40).padding(EdgeInsets.all(5)),
                                      ],),
                                      Align(child: schemeImg.SIZED(width: 100).FITTED(BoxFit.fitWidth), alignment: Alignment.centerLeft).padding(EdgeInsets.symmetric(horizontal: 7.5)),
                                    ],),

                                 Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Container(child: Text(text,), width: MediaQuery.of(context).size.width - 115),

                                     isChallenger ? RaisedButton(child: Text('REVOKE'), onPressed: (){}, color: Colors.red,)
                                      : Row(children: [
                                       RaisedButton(child: Text('DECLINE'), onPressed: () {  }, color: Colors.red,).EXPANDED().padding(EdgeInsets.all(10)),
                                       RaisedButton(child: Text('ACCEPT'), onPressed: () { }, color: Colors.green).EXPANDED().padding(EdgeInsets.all(10)),
                                     ]).SIZED(width: MediaQuery.of(context).size.width - 115)//.padding(EdgeInsets.all(20)).EXPANDED()
                                   ],
                                 )

                                 // Text(text)
                                ],
                              ).padding(EdgeInsets.symmetric(vertical: 10));

                            }).FLEXIBLE(),

                        SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          child:  Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              friendsList.isEmpty ? Center(child:
                              Text('You haven\'t added any friends yet', style: TextStyle(color: Colors.white),).padding(EdgeInsets.symmetric(vertical: 16, horizontal: 16)))
                                  : ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: friendsList.length,
                                  itemBuilder: (context, i) {
                                    UserMetadata userData = friendsList[i];
                                    bool userIsDisplay = userData.userName == userData.displayName;
                                    return ListTile(
                                      title: Text(!userIsDisplay ? userData.displayName : userData.userName),
                                      subtitle: Text(!userIsDisplay ? userData.userName : ''),
                                      leading: Image(image: Image.asset(Assets.DEFAULT_USER).image),
                                      trailing: FlatButton(onPressed: () { challengeUser(userData, user, schemeEquipped); }, child: Image.asset(Assets.FISTS))
                                    );
                                  }).FLEXIBLE(),

                              friendRequests.isEmpty ? Empty().FLEXIBLE()
                                  : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    Align(child: Text('Friend Requests', style: TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),).padding(EdgeInsets.symmetric(horizontal: 16, vertical: 0)), alignment: Alignment.centerLeft,).EXPANDED(),
                                  ],),
                                  ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: friendRequests.length,
                                      itemBuilder: (context, i) {
                                        UserMetadata userData = friendRequests[i];
                                        bool userIsDisplay = userData.userName == userData.displayName;
                                        return ListTile(
                                          title: Text(!userIsDisplay ? userData.displayName : userData.userName),
                                          subtitle: Text(!userIsDisplay ? userData.userName : ''),
                                            leading: Image(image: Image.asset(Assets.DEFAULT_USER).image),
                                            trailing: FittedBox(
                                              fit: BoxFit.fitHeight,
                                              child: Column(
                                                children: [
                                                  FlatButton(onPressed: () { addFriend(user, userData); }, child: Image.asset(Assets.ADD_ICON)),
                                                  FlatButton(onPressed: () { challengeUser(userData, user, schemeEquipped); }, child: Image.asset(Assets.FISTS))

                                                ],
                                              ),
                                            )
                                        );
                                      }).FLEXIBLE()
                                ],
                              ).FLEXIBLE(),


                              friendsPending.isEmpty ? Empty().FLEXIBLE()
                                  : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    Align(child: Text('Pending Response', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),).padding(EdgeInsets.symmetric(horizontal: 16, vertical: 0)), alignment: Alignment.centerLeft,).EXPANDED(),
                                  ],),
                                  ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: friendsPending.length,
                                      itemBuilder: (context, i) {
                                        UserMetadata userData = friendsPending[i];
                                        bool userIsDisplay = userData.userName == userData.displayName;
                                        return ListTile(
                                          title: Text(!userIsDisplay ? userData.displayName : userData.userName),
                                          subtitle: Text(!userIsDisplay ? userData.userName : ''),
                                            leading: Image(image: Image.asset(Assets.DEFAULT_FIGHTER).image),
                                            trailing: FlatButton(onPressed: () { challengeUser(userData, user, schemeEquipped); }, child: Image.asset(Assets.FISTS))
                                        );
                                      }).FLEXIBLE()
                                ],
                              ).FLEXIBLE()





                            ],
                          )
                        )


                        ,

                      ],
                    ).EXPANDED(),


                  // PLAYER SEARCH
                  Row(
                   //mainAxisSize: MainAxisSize.min,

                    children: [
                      TextField(
                        controller: _textEditController,
                      decoration: new InputDecoration.collapsed(
                          hintText: 'Search for player',
                        hintStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        fillColor: Colors.blue
                      ),
                    ).EXPANDED(),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white,), onPressed: () {
                          String userToSearch = _textEditController.value.text.trim();
                         data.appStateEventSink.add(SubmitSearchForUserEvent(userToSearch));
                         print('searching $userToSearch');
                      },).FLEX(0)
                    ],
                  ).FLEX(0)

                  //   Container(color: Colors.red).FLEX(0),
                  //   Container(color: Colors.blue).EXPANDED(),
                  //   Container(child: Text('111'), color: Colors.red).FLEX(0),



                  ],
                )

            //  )
                  .MY_BACKGROUND_CONTAINER(),
            ),
          );

          });

  }

  void addFriend(User user, UserMetadataWithKey userDataWithKey) {
    net.AcceptFriendRequest(user, userDataWithKey.key);
  }
}








