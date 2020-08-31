import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/appstate_states.dart';
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/main.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/widgets/my_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:edojo/widgets/extensions.dart';

class ChallengesPage extends StatefulWidget {
  @override
  _ChallengesPageState createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin{

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    data.appStateEventSink.add(RefreshSchemesEditingAndOwned());
    data.appStateEventSink.add(RefreshFriendCodesAndChallengeCodes());

    _tabController = TabController(vsync: this, length: 2);

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
          List<Challenge> challengersList = dm.challengesList;

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
                            Text('You have no pending challenges', style: TextStyle(color: Colors.white),)
                        )
                            : ListView.builder(itemBuilder: (context, i) {
                              Challenge ch = challengersList[i];
                          return ListTile(
                            title: Text(ch.player1Id + ' vs ' + ch.player2Id),
                          );
                        }),

                        friendsList.isEmpty ? Center(child:Text('You haven\'t added any friends yet', style: TextStyle(color: Colors.white),))
                            : ListView.builder(itemBuilder: (context, i) {
                              UserMetadata userData = friendsList[i];
                              bool userIsDisplay = userData.userName == userData.displayName;
                              return ListTile(
                                title: Text(!userIsDisplay ? userData.displayName : userData.userName),
                                subtitle: Text(!userIsDisplay ? userData.userName : ''),
                          );
                        }),

                      ],
                    ).EXPANDED() ,

                  Column(
                   mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                      decoration: new InputDecoration.collapsed(
                          hintText: 'Search for player',
                        hintStyle: TextStyle(fontStyle: FontStyle.italic)
                      ),
                    )
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



