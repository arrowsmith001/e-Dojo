import 'package:auto_size_text/auto_size_text.dart';
import 'package:dotted_border/dotted_border.dart';
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
import 'dart:math' as Math;

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

  void addFriend(User user, UserMetadataWithKey userDataWithKey) {
    net.AcceptFriendRequest(user, userDataWithKey.key);
  }

  void goToChallenge(Challenge ch) {

    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) { return ChallengePage(ch); }));

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
                  ).PADDING(EdgeInsets.symmetric(horizontal: 16.0)).EXPANDED()],
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
                            Text('You have no pending challenges', style: TextStyle(color: Colors.white),).PADDING(EdgeInsets.symmetric(vertical: 16, horizontal: 16))
                        )
                            : ListView.builder(
                            shrinkWrap: true,
                            itemCount: challengersList.length,
                            itemBuilder: (context, i) {

                              Challenge ch = challengersList[i];

                              String schemeName = ch.meta.schemeName;
                              String p1name = ch.meta.player1Username;
                              String p2name = ch.meta.player2Username;

                              Image schemeImg = ch.meta.schemeImg;

                              Image p1Img = ch.meta.player1.GetImage();
                              Image p2Img = ch.meta.player2.GetImage();

                              bool isChallenger = p1name == user.meta.userName;
                              String text = isChallenger ? 'You challenged ' + p2name + ' to ' + schemeName
                                  : p1name + ' challenged you to ' + schemeName;

                              // Challenge listing item
                              return Row(
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(children: [
                                        p1Img.SIZED(width: 40).PADDING(EdgeInsets.all(5)),
                                        Text('vs'),
                                        p2Img.SIZED(width: 40).PADDING(EdgeInsets.all(5)),
                                      ],),
                                      Align(child: schemeImg.SIZED(width: 100)//.FITTED(BoxFit.fitWidth)
                                          , alignment: Alignment.centerLeft).PADDING(EdgeInsets.symmetric(horizontal: 7.5)),
                                    ],),

                                 Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [

                                     Container(child: Text(text,), width: MediaQuery.of(context).size.width - 115),

                                     isChallenger ?
                                     Row(children: [
                                       RaisedButton(child: Text('REVOKE'), onPressed: () {  }, color: Colors.red).PADDING(EdgeInsets.all(10)).EXPANDED(),
                                       RaisedButton(child: Text('GO'), onPressed: () { goToChallenge(ch); }, color: Colors.green).PADDING(EdgeInsets.all(10)).EXPANDED(),
                                     ]).SIZED(width: MediaQuery.of(context).size.width - 115)
                                      : Row(children: [
                                       RaisedButton(child: Text('DECLINE'), onPressed: () {  }, color: Colors.red).PADDING(EdgeInsets.all(10)).EXPANDED(),
                                       RaisedButton(child: Text('GO'), onPressed: () { goToChallenge(ch); }, color: Colors.green).PADDING(EdgeInsets.all(10)).EXPANDED(),
                                     ]).SIZED(width: MediaQuery.of(context).size.width - 115)

                                   ],).FLEXIBLE()
                                ],
                              ).PADDING(EdgeInsets.symmetric(vertical: 10));

                            }),

                        SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          child:  Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              friendsList.isEmpty ? Center(child:
                              Text('You haven\'t added any friends yet', style: TextStyle(color: Colors.white),).PADDING(EdgeInsets.symmetric(vertical: 16, horizontal: 16)))
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
                                    Align(child: Text('Friend Requests', style: TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),).PADDING(EdgeInsets.symmetric(horizontal: 16, vertical: 0)), alignment: Alignment.centerLeft,).EXPANDED(),
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
                                    Align(child: Text('Pending Response', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),).PADDING(EdgeInsets.symmetric(horizontal: 16, vertical: 0)), alignment: Alignment.centerLeft,).EXPANDED(),
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


}

class ChallengePage extends StatefulWidget {
  ChallengePage(this.ch);

  final Challenge ch;

  @override
  _ChallengePageState createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> with TickerProviderStateMixin {

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  GameScheme scheme;

  AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // Listen for challenges, fetch scheme itself
    net.SetChallengeListener(widget.ch.meta.challengeId, true);
    GetGameScheme();
  }

  void GetGameScheme() async{
    scheme = await net.GetSchemeFromCode(widget.ch.meta.schemeId);
    setState(() { });
  }

  @override
  void dispose() {
    super.dispose();

    // Stop listening to challenges
    net.SetChallengeListener(widget.ch.meta.challengeId, false);

    _animController.dispose();
  }

  void togglePlayerSelect() {

  setState(() {
    //showingFighterSelect = !showingFighterSelect;

    if(!animForward) { _animController.reverse();  }
    else {  _animController.forward(); }

    animForward = !animForward;
  });
  }

  bool animForward = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateState>(
        stream: data.appStateStream,
        initialData: AppStateState(data.model),
    builder: (context, snapshot) {


      DataModel dm = snapshot.data.model;
      Image schemeImg = widget.ch.meta.schemeImg;

      return scheme == null ? CircularProgressIndicator()
       : SafeArea(
        child: Scaffold(
         appBar: MyAppbar(
           title:
           schemeImg.image == null ? Text(widget.ch.meta.schemeName, style: TextStyle(color: Colors.white),)
            : Image(image: schemeImg.image, fit: BoxFit.fitHeight, height: 45),
           actions: [
            // FlatButton(onPressed: () { togglePlayerSelect(); }, child: Text('toggle'),)
           ],
         ),

         body: Stack(
           children: [
             // STACK ELEMENT 1: BASE PAGE
             Column(
               children: [
                 Align(
                     alignment: Alignment.topCenter,
                     child:  Row(
                         children: [

                           Column(
                               children: [

                                 Text(widget.ch.meta.player1Username).PADDING(EdgeInsets.symmetric(horizontal: 10, vertical: 6)).FLEXIBLE(),

                                 ListView.builder(
                                     itemCount: 3,
                                     itemBuilder: (context, i){
                                       return FighterEntry(this).PADDING(EdgeInsets.symmetric(horizontal: 10, vertical: 6));

                                     }).FLEXIBLE(),
                               ]
                           ).EXPANDED(),

                           Column(
                               children: [

                                 Text(widget.ch.meta.player2Username).PADDING(EdgeInsets.symmetric(horizontal: 10, vertical: 6)).FLEXIBLE(),

                                 ListView.builder(
                                     itemCount: 3,
                                     itemBuilder: (context, i){
                                       return FighterEntry(this).PADDING(EdgeInsets.symmetric(horizontal: 10, vertical: 6));

                                     }).FLEXIBLE(),
                               ]
                           ).EXPANDED(),

                         ]
                     )

                 ).MY_BACKGROUND_CONTAINER().EXPANDED(),
               ],
             ),

             // STACK ELEMENT 2: Fighter select FighterSelectTableFromScheme(scheme)
             //!showingFighterSelect ? Empty()
               AnimatedBuilder(
               animation: _animController,
               builder:(context, child){
                 double val = Math.pow( _animController.value, 3);
                 return Opacity(
                   opacity: val,
                   child: Transform.translate(
                       offset: Offset(0, (1-val)*200),
                       child: Column(
                         children: [
                           Empty().EXPANDED(),
                           Container(
                             child: Align(child: FighterSelectTableFromScheme(scheme, (MediaQuery.of(context).size.width - 10) / (scheme.grid.dim.maxCol + 1)), alignment: Alignment.center,).PADDING(EdgeInsets.all(5)),
                             decoration: BoxDecoration(
                                 // borderRadius: BorderRadius.circular(20),
                                 // color: Colors.indigo,
                                 border: Border(
                                   top: BorderSide(
                                     color: Colors.white,
                                     width: 2,
                                     style: BorderStyle.solid,
                                   ),
                                 )
                             ),).EXPANDED()

                         ],
                       )),

                 );
               }
             ),

           ],
         )

      )
      );




    }
    );
  }


}

class FighterEntry extends StatelessWidget{

  FighterEntry(this.parentState);
  _ChallengePageState parentState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (){ parentState.togglePlayerSelect(); }, // TODO Touching selects field for entry (if on player side)
          child: DottedBorder(
            color: Colors.white,
            strokeWidth: 2,
            dashPattern: [
              4
            ],
            borderType: BorderType.RRect,
            radius: Radius.circular(5),
              child: Text('ENTER YOUR FIGHTER').PADDING(EdgeInsets.symmetric(horizontal: 5, vertical: 16)),
          ),
        );
  }

}

class FighterSelectTableFromScheme extends StatefulWidget {

  FighterSelectTableFromScheme(this.scheme, this.initDim);
  GameScheme scheme;
  double initDim;

  @override
  _FighterSelectTableFromScheme createState() => _FighterSelectTableFromScheme(initDim);
}

class _FighterSelectTableFromScheme extends State<FighterSelectTableFromScheme> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  final _scrollController = new ScrollController(keepScrollOffset: false);
  final _scrollController2 = new ScrollController(keepScrollOffset: false);


  List<TableRow> tableRows;

  double boxDim;
  double localScale = 1;
  double boxDimTemp;

  _FighterSelectTableFromScheme(double initDim){
    this.boxDim = initDim;
    this.boxDimTemp = initDim;
  }

  void ChangeDim(double newDim, bool set)
  {
    setState(() {
      if(set) {
        boxDim = newDim;
        boxDimTemp = newDim;
      }
      else boxDim = boxDimTemp*localScale;
    });
  }

  void HandleTap(int i, int j) {
    // TODO Touching enters fighter for selected fighter entry, and moves selection on
  }

  void HandleLongPress(int i, int j) {

  }

  @override
  Widget build(BuildContext context) {

    int rows = widget.scheme.grid.dim.maxRow;
    int cols = widget.scheme.grid.dim.maxCol;

    tableRows = new List();

    for(int i = 0; i <= rows; i++)
    {
      List<Widget> rowContents = [];

      for(int j = 0; j <= cols; j++)
      {
        // OPTION 1: Text representation
        Widget textWidget = FittedBox(
            fit: BoxFit.fitHeight,
            child: AutoSizeText(widget.scheme.grid.getSquare(i, j).GetName())
        );

        // OPTION 2: Image representation
        Widget imgWidget = FittedBox(
            fit: BoxFit.fill,
            child: widget.scheme.grid.getSquare(i, j).GetImage(1)
        );

        rowContents.add(
            StreamBuilder<AppStateState>(
                initialData: AppStateState(data.model),
                stream: data.appStateStream,
                builder: (context, snapshot) {

                  DataModel model = snapshot.data.model;

                  return GestureDetector(
                    onLongPress: () {HandleLongPress(i, j);},
                    onTap: () { HandleTap(i, j); },
                    child:
                    SizedBox(
                        width: boxDim,
                        height: boxDim,
                       // child: (model.schemeEditorState.schemeEditorGridSelection.compare(i, j) ?
                       // imgWidget.BORDER(model.schemeEditorState.swapMode ? Colors.purpleAccent : Colors.yellow, 3.0) : imgWidget).PADDING(EdgeInsets.all(2))
                      child: imgWidget.PADDING(EdgeInsets.all(2)),
                    ),
                  );
                }
            )
        );
      }
      tableRows.add(new TableRow(
          children: rowContents
      ));
    }


    return
      FutureBuilder<Image>(
        builder: (context,snapshot) {

          return GestureDetector(
            onScaleUpdate: (details){
              localScale = details.scale;
              ChangeDim(localScale * boxDimTemp, false);
            },
            onScaleEnd: (details) {
              ChangeDim(localScale * boxDimTemp, true);
              localScale = 1;
            },
            child: Scrollbar(
                controller: _scrollController2,
                child: ListView(
                    children: <Widget>[
                      SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child:
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Center(child:

                              Container(
                                child: Table(
                                  //border: TableBorder.all(color: Colors.red),
                                    defaultColumnWidth: IntrinsicColumnWidth(),
                                    children: tableRows
                                ),
                              )

                              ),
                            ],
                          )
                      )
                    ])),
          );
        },
      );
  }
}







