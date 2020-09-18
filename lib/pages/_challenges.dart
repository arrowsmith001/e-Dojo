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

  AnimationController _animController;

  int selectedFighter;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // Listen for challenges, fetch scheme itself
    net.SetChallengeListener(widget.ch.meta.challengeId, true);
    GetGameScheme();
  }

  void GetGameScheme() async{

    GameScheme scheme = await net.GetSchemeFromCode(widget.ch.meta.schemeId);
    data.appStateEventSink.add(ChallengeStartedEvent(widget.ch, scheme));

    setState(() { });
  }

  @override
  void dispose() {
    super.dispose();

    // Stop listening to challenges
    net.SetChallengeListener(widget.ch.meta.challengeId, false);

    // Briefly exited from challenge (not closed)
    data.appStateEventSink.add(ChallengeExitedEvent(widget.ch));

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

  // Fighter table controls
  FighterSelectTableFromScheme fighterTable;
  bool animForward = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateState>(
        stream: data.appStateStream,
        initialData: AppStateState(data.model),
    builder: (context, snapshot) {

      DataModel dm = snapshot.data.model;
      GameScheme scheme = dm.challengeState.GetScheme();

      // TODO Introduce and make changeable these two variables
      // Have readystate determine challenge page state
     bool isP1Ready = widget.ch.state.p1Ready;
     bool isP2Ready = widget.ch.state.p2Ready;

      Image schemeImg = widget.ch.meta.schemeImg;
      int maxFighters = widget.ch.meta.maxFighters;

      if(scheme == null || scheme.grid == null) return CircularProgressIndicator();

      fighterTable =
          FighterSelectTableFromScheme(togglePlayerSelect, scheme, (MediaQuery.of(context).size.width - 10) / (scheme.grid.dim.maxCol + 1));

      bool isP1 = widget.ch.meta.player1.userName == dm.user.meta.userName;
      bool isP2 = widget.ch.meta.player2.userName == dm.user.meta.userName;

      List<Widget> p1ColChildren = new List<Widget>();
      p1ColChildren.add(Text(widget.ch.meta.player1.userName, textAlign: TextAlign.end,).FLEX(0));
      for(int i = 0; i < maxFighters; i++){
        p1ColChildren.add(FighterEntry(this, 1, i, isP1).EXPANDED());
      }

      List<Widget> p2ColChildren = new List<Widget>();
      p2ColChildren.add(Text(widget.ch.meta.player2.userName).FLEX(0));
      for(int i = 0; i < maxFighters; i++){
        p2ColChildren.add(FighterEntry(this, 2, i, isP2).EXPANDED());
      }

      return SafeArea(
        child: Scaffold(
         appBar: MyAppbar(
           title: Center(child:
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
             widget.ch.meta.player1.GetImage().SIZED(height: 50, width: 50).FLEXIBLE(),
             scheme.meta.iconImg.FLEXIBLE(),
             widget.ch.meta.player2.GetImage().SIZED(height: 50, width: 50).FLEXIBLE() ])),
           actions: [
            IconButton(icon: Icon(Icons.more_vert, color: Colors.white), onPressed: () {  },).PADDING(EdgeInsets.fromLTRB(5, 0,0,0))
           ],
         ),

         body: Column(
           children: [
             //Empty().EXPANDED(),
             Container(
               child: Row(
                 children: [

                   Column(
                     children: p1ColChildren,
                   )
                       .EXPANDED(),

                   Column(
                     children: p2ColChildren,
                   )
                       .EXPANDED(),

                 ],
               )
             ).FLEX(1),

             Container(
               child: Align(
                 child: fighterTable, alignment: Alignment.center,).PADDING(EdgeInsets.all(5)),
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
               ),).FLEX(2),

             Row(
               children: [
                 Text('P1').EXPANDED(),
                 Text('P2').EXPANDED(),
                 RaisedButton(
                   onPressed: () {  },
                   child: Text('READY'),
                 ).EXPANDED()
               ]
             )

           ],
         ).MY_BACKGROUND_CONTAINER(),

      )
      );
    }
    );
  }




}



class FighterEntry extends StatefulWidget{
  FighterEntry(this.parentState, this.playerNum, this.fighterNum, this.isUser );
  _ChallengePageState parentState;
  final bool isUser;
  final int playerNum;
  final int fighterNum;

  @override
  _FighterEntryState createState() => _FighterEntryState();

}

class _FighterEntryState extends State<FighterEntry> {

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  bool willAccept = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateState>(
      stream: data.appStateStream,
      initialData: AppStateState(data.model),
      builder: (context, ds) {

        DataModel dm = ds.data.model;

        bool selected = (widget.isUser && widget.fighterNum == dm.challengeState.entrySelection);

        return StreamBuilder<AppStateState>(
            stream: data.appStateStream,
            initialData: new AppStateState(data.model),
            builder: (context, snapshot) {

              double height = 50;

              FighterScheme fighter = snapshot.data.model.challengeState.GetFighter(widget.playerNum, widget.fighterNum);
              String variant = snapshot.data.model.challengeState.GetVariant(widget.playerNum, widget.fighterNum);

              Widget text = FittedBox(
                  child: AutoSizeText.rich(
                    TextSpan(children: [
                      TextSpan(text: fighter == null ? widget.isUser ? 'SELECT FIGHTER' : '' : fighter.fighterName),
                      TextSpan(text: variant == null ? '' : '\n' + variant, style: TextStyle(fontSize: 10))
                    ] ),
                    maxLines: 2,
                    maxFontSize: 50,
                    minFontSize: 10,
                    textAlign: TextAlign.center,)
                      .PADDING(EdgeInsets.symmetric(horizontal: 15, vertical: 10)), fit: BoxFit.fitHeight)
                  .SIZED(height: height)
                  .EXPANDED();

              Widget image = fighter == null ? Empty() : FittedBox(fit: BoxFit.fitWidth, child: fighter.GetFighterImage()).SIZED(width: height, height: height);

              Widget content = Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.playerNum == 1 ? text : image,
                      widget.playerNum == 1 ? image : text,
                    ]
                ),
              );

              return Column(
                children: [
                  Container(
                    color: !widget.isUser ? Colors.grey.withAlpha(50) : Colors.transparent,
                    child: InkWell(
                      onTap: (){
                        if(!widget.isUser) return;
                        widget.parentState.togglePlayerSelect();
                        data.appStateEventSink.add(FighterEntrySelectionEvent(widget.fighterNum));
                      }, // TODO Touching selects field for entry (if on player side)
                      child: DottedBorder(
                        color: !widget.isUser ? Colors.blueGrey : willAccept ? Colors.yellow : Colors.white,
                        strokeWidth: selected ? 5 : 2,
                        dashPattern: [
                          fighter != null ? 0.1 : 5
                        ],
                        borderType: BorderType.RRect,
                        radius: Radius.circular(5),
                        child: content
                        ),
                      ),
                    ).EXPANDED(),
                ],
              ).PADDING(EdgeInsets.all(4));
            }
        );
      }
    );
  }
}




class FighterSelectTableFromScheme extends StatefulWidget {

  FighterSelectTableFromScheme(this.toggleInParent, this.scheme, this.initDim);
  GameScheme scheme;
  double initDim;
  Function toggleInParent;

  final scrollControllerH = new ScrollController(keepScrollOffset: false);
  final scrollControllerV = new ScrollController(keepScrollOffset: false);

  @override
  _FighterSelectTableFromScheme createState() => _FighterSelectTableFromScheme(initDim);
}

class _FighterSelectTableFromScheme extends State<FighterSelectTableFromScheme> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

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

  void HandleTap(int i, int j, int fighterSelected, int pNum, ChallengeState state) {
    Square squareSelected = widget.scheme.grid.getSquare(i, j);
    FighterScheme fighter = squareSelected.fighter;
    if(fighter == null) return;

    //_scrollController.animateTo(j*boxDim, duration: Duration(milliseconds: 200), curve: Curves.easeIn);
    if(state.challengeInProgress.IsFighterInSelections(squareSelected, pNum))
      {
        data.appStateEventSink.add(FighterEntrySelectionEvent(state.challengeInProgress.IndexOf(fighter, pNum)));
        data.appStateEventSink.add(FighterUnselectedEvent(fighter, pNum));
      }
    else
      {
        // TODO Option to change variation

        // Open alert box
        // Select variation from options (or none)
        // Send event to select/equip variant
        // Reflect change in Fighter Entry

        if(fighter.HasVariants())
          {

            showDialog<String>(context: context, builder: (context) {
              return VariantDialog(fighter); }).then((varString) {

                if(varString != null){
                  if(varString != ''){
                    data.appStateEventSink.add(FighterSelectedEvent(fighter, varString, pNum, fighterSelected));
                    data.appStateEventSink.add(FighterEntrySelectionEvent(null));
                  }else
                    {

                      data.appStateEventSink.add(FighterSelectedEvent(fighter, null, pNum, fighterSelected));
                      data.appStateEventSink.add(FighterEntrySelectionEvent(null));
                    }

                }
            });
          }else
            {
              data.appStateEventSink.add(FighterSelectedEvent(fighter, null, pNum, fighterSelected));
              data.appStateEventSink.add(FighterEntrySelectionEvent(null));
            }
      }

  }

  void HandleLongPress(int i, int j) {
    print('longpress');
    setState(() {

    });
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
        Square square = widget.scheme.grid.getSquare(i, j);
        // OPTION 1: Text representation
        Widget textWidget = FittedBox(
            fit: BoxFit.fitHeight,
            child: AutoSizeText(square.GetName())
        );

        // OPTION 2: Image representation
        Widget imgWidget = SizedBox(
          width: 50, height: 50,
            child: FittedBox(
              fit: BoxFit.contain,
              child: square.GetImage(0.7)
          )
        );

        rowContents.add(
            StreamBuilder<AppStateState>(
                initialData: AppStateState(data.model),
                stream: data.appStateStream,
                builder: (context, snapshot) {

                  DataModel model = snapshot.data.model;
                  int fighterSelected = model.challengeState.entrySelection;
                  int pNum = model.challengeState.challengeInProgress.meta.player1.userName == model.user.meta.userName ? 1 :
                    model.challengeState.challengeInProgress.meta.player2.userName == model.user.meta.userName ? 2 : 0;

                  bool p1Selected = model.challengeState.challengeInProgress.IsFighterInSelections(square, 1);
                  bool p2Selected = model.challengeState.challengeInProgress.IsFighterInSelections(square, 2);

                  Widget squareChild = GestureDetector(
                    onLongPress: () {HandleLongPress(i, j);},
                    onTap: () {
                        HandleTap(i, j, fighterSelected, pNum, model.challengeState);

                      },
                    child:
                    SizedBox(
                      width: boxDim,
                      height: boxDim,
                      // child: (model.schemeEditorState.schemeEditorGridSelection.compare(i, j) ?
                      // imgWidget.BORDER(model.schemeEditorState.swapMode ? Colors.purpleAccent : Colors.yellow, 3.0) : imgWidget).PADDING(EdgeInsets.all(2))
                      child: Stack(
                        children: [
                          Column(
                            children: [ imgWidget.PADDING(EdgeInsets.all(2)).EXPANDED() ],
                          ),

                          !p1Selected ? Empty() : Column(
                            children: [ Align(alignment: Alignment.topLeft,
                                child: Container(color: Colors.purple,
                                    child: AutoSizeText(' 1 ', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold), minFontSize: 16, maxFontSize: 50)))
                                .PADDING(EdgeInsets.all(4)).EXPANDED() ],
                          ),

                          !p2Selected ? Empty() : Column(
                            children: [ Align(alignment: Alignment.bottomRight,
                                child: Container(color: Colors.yellow,
                                    child: AutoSizeText(' 2 ', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold), minFontSize: 16, maxFontSize: 50)))
                                .PADDING(EdgeInsets.all(4)).EXPANDED() ],
                          ),
                        ],
                      ),
                    ),
                  );

                  double feedbackSize = 50;

                  return squareChild;
                }
            )
        );
      }
      tableRows.add(new TableRow(
          children: rowContents
      ));
    }


    return
      GestureDetector(
        onScaleStart: (details){

        },
        onScaleUpdate: (details){
          localScale = details.scale;
          ChangeDim(localScale * boxDimTemp, false);
        },
        onScaleEnd: (details) {
          ChangeDim(localScale * boxDimTemp, true);
          localScale = 1;
        },
        child: Stack(
            children:[
              Scrollbar(
                controller: widget.scrollControllerV,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        controller: widget.scrollControllerH,
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

                  ],
                ),
              ),
            ]
        ) ,

      );
  }
}

// Return varString of variant, Return null for 'cancel'
class VariantDialog extends StatefulWidget {
  VariantDialog(this.fighter);
  FighterScheme fighter;

  @override
  _VariantDialogState createState() => _VariantDialogState();
}

class _VariantDialogState extends State<VariantDialog> {
  @override
  Widget build(BuildContext context) {

    List<Widget> colChildren = new List<Widget>();

    colChildren.add(Empty().EXPANDED());

    // Add variant buttons
  for(int i = 0; i < widget.fighter.variants.length; i++){
    colChildren.add(
        new VariantEntry(widget.fighter.variants[i], widget.fighter.variants[i], Colors.indigo[700]).PADDING(EdgeInsets.symmetric(vertical: 10)));
  }


    colChildren.add(new VariantEntry('No variant specified', '', Colors.indigo[900]).PADDING(EdgeInsets.symmetric(vertical: 10)));

    colChildren.add(new VariantEntry('CANCEL', null, Colors.red[900]).PADDING(EdgeInsets.symmetric(vertical: 10)));


    return Dialog(

      backgroundColor: Colors.transparent,
      child: Center(
        child: Column(
          children: colChildren
        ),
      ),
    );
  }
}

class VariantEntry extends StatelessWidget {
  VariantEntry(this.variant, this.value, this.color);
  String variant;
  String value;
  Color color;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.of(context).pop(value);
      },
      child: Container(
        height: 60,
        child: Center(child: AutoSizeText(variant, style: TextStyle(color: Colors.white), minFontSize: 16, maxFontSize: 30).PADDING(EdgeInsets.all(20))),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: color
        ),
      ),
    );
  }
}











