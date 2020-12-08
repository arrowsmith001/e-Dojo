
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/presentation/edojo_icons_icons.dart';
import 'package:edojo/widgets/my_app_bar.dart';

import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_states.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/pages/_schemes.dart';
import 'package:edojo/tools/assets.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:edojo/widgets/extensions.dart';

import '../main.dart';
import '_challenges.dart';

class HomePage extends StatefulWidget{


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AuthState>(
        stream: data.authStream,
        initialData: AuthState(data.model),
        builder: (context, snapshot) {
          AuthState ds = snapshot.data;

          if(ds is LogOutState || ds is DeterminingProfileCompletionState)
          {
            return Loading();
          }

          if(!ds.data.isUserSetUp()) return CompleteSetup();

          return HomeDefault();

        });
  }

}

class HomeDefault extends StatefulWidget {
  @override
  _HomeDefaultState createState() => _HomeDefaultState();
}

class _HomeDefaultState extends State<HomeDefault> with SingleTickerProviderStateMixin{

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this._tabController = new TabController(length: 4, vsync: this);
  }

  void OnSignOutSelect() {
    net.SignOut();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return StreamBuilder<AuthState>(
        stream: data.authStream,
        initialData: AuthState(data.model),
        builder: (context, snapshot) {
          AuthState ds = snapshot.data;

          return Scaffold(
            drawer: Drawer(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Clear all cached data', style: TextStyle(color: Colors.black)),
                    onTap: (){ data.appStateEventSink.add(ClearCacheEvent()); },
                  )
                ]
              )
            ),
              appBar: MyAppbar(
                //leading: Icon(Icons.arrow_back, color: Colors.white,),
                title: Text(
                    'Welcome ${ds.data.user.meta.displayName}',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                actions: [
                  FlatButton(
                    onPressed: () {
                      net.SignOut();
                    },
                  child: Text('Sign out', style: TextStyle(color: Colors.white),),

                  )
                ],
//                startColor: Color.fromRGBO(3, 5, 9, 1.0),
//                endColor: Color.fromRGBO(32, 56, 100, 1.0),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        ChallengesPage(),
                        SchemesPage(),
                        Empty(),
                        Empty()
                      ],

                    ).EXPANDED(),
                    Container(
                      height: 50,
                      child: TabBar(
                        controller: _tabController,
                        tabs: [
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(EdojoIcons.home_fists), AutoSizeText('Challenges', minFontSize: 10,).FLEXIBLE()]),
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(EdojoIcons.game_default), AutoSizeText('Games', minFontSize: 10,).FLEXIBLE()]),
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(EdojoIcons.fighter_default), AutoSizeText('Profile', minFontSize: 10,).FLEXIBLE()]),
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(EdojoIcons.home_data), AutoSizeText('Data', minFontSize: 10,).FLEXIBLE()]),
                        ],

                      ),
                    )

                  ],
                )




                // // OLD
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: <Widget>[
                //     Center(
                //       child: GridView.count(
                //         shrinkWrap: true,
                //           crossAxisCount: 2,
                //           children: <Widget>[
                //             BigMainButton(context, image: Image.asset(Assets.FISTS), widget: ChallengesPage(), color: Colors.yellow, title: 'Challenges').PADDING(EdgeInsets.all(20.0)),
                //             BigMainButton(context,image: Image.asset(Assets.FIGHTER), widget: Empty(), color: Colors.blue, title: 'View Fighter Profile').PADDING(EdgeInsets.all(20.0)),
                //             BigMainButton(context, image: Image.asset(Assets.GAME),widget: SchemesPage(), color: Colors.purpleAccent, title: 'Manage Schemes').PADDING(EdgeInsets.all(20.0)),
                //             BigMainButton(context,image: Image.asset(Assets.DATA), widget: Empty(), color: Colors.orange, title: 'Explore Data').PADDING(EdgeInsets.all(20.0)),
                //             BigMainButton(context,image: Image.asset(Assets.DATA), widget: Empty(), color: Colors.grey, title: 'General settings').PADDING(EdgeInsets.all(20.0)),
                //             BigMainButton(context,image: Image.asset(Assets.DATA), widget: Empty(), color: Colors.grey, title: 'Account settings').PADDING(EdgeInsets.all(20.0)),
                //
                //           ]),
                //     ).EXPANDED()
                //   ],
                // ).MY_BACKGROUND_CONTAINER(),


              ),
            );
        });
  }
}






class BigMainButton extends StatelessWidget{
  BigMainButton(this.context0, {this.image, this.widget, this.color, this.title});
  final String title;

  BuildContext context0;
  Color color;
  Widget widget;
  Image image;

  void Navigate(){
    Navigator.of(context0).push(MaterialPageRoute(builder: (BuildContext context) { return widget; }));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return InkWell(
      onTap: (){
        Navigate();
      },
      child: Container(
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(color: this.color, image: image.image, height: 150, fit: BoxFit.fill,).FLEX(3),
            Text(this.title, style: TextStyle(color: this.color, fontWeight: FontWeight.bold)).FLEX(3),
          ],
        ),
        decoration: BoxDecoration(
            border: Border.all(width: 5, color: this.color),
            borderRadius: BorderRadius.all(Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: this.color.withAlpha(70),
                blurRadius: 50.0,
                spreadRadius: 10.0,
                offset: Offset(0.0, 0.0,
                ),
              ),
            ]
        ),
      )
    );
  }

}

class CompleteSetup extends StatefulWidget {

  final String title = 'Complete registration';

  @override
  _CompleteSetupState createState() => _CompleteSetupState();
}

class _CompleteSetupState extends State<CompleteSetup> {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final GlobalKey<AnimatedListState> _myListKey = GlobalKey<AnimatedListState>();

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  void OnDetailsSubmitted(Map<String, dynamic> map, User user) {
    net.CompleteProfile(user, map['Username'], map['Display name']);
  }

  List<Widget> list = [];
  Widget userName, displayName, checkBox;

  bool checked = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    userName =  FormBuilderTextField(
      initialValue: '',
      attribute: 'Username',
      decoration: InputDecoration(labelText: 'Username'),
      validators: [
        FormBuilderValidators.required()
      ],
    );

    displayName =  FormBuilderTextField(
      initialValue: '',
      attribute: 'Display name',
      decoration: InputDecoration(labelText: 'Display name'),
      validators: [
        FormBuilderValidators.required()
      ],
    );

    checkBox = FormBuilderCheckbox(
      initialValue: true,
      attribute: 'Display name is username?',
      label: Text('Display name is username?'),
      onChanged: (b) {
        //toggleDisplayName(b);
      },
    );

    list = [
      userName,
      displayName,
      checkBox,
    ];
  }

  void toggleDisplayName(b) {
    if (b) {
      print('b TRUE');
      if(list.length == 3)
        {
//          _myListKey.currentState.removeItem(1, (context, animation) {
//            return checkBox;
//          });
      setState(() {

        list.remove(list[2]);
      });
        }

    }
    else {
      print('b FALSE');
      //_myListKey.currentState.insertItem(1, duration: Duration(seconds: 1));
      setState(() {

        list.insert(1, displayName);
      });
    }
  }
    void FinishSetup(User user, String userName, String displayName) {
      net.CompleteProfile(data.model.user, userName, displayName);
    }

    bool usernameIsDisplayname = true;

    @override
    Widget build(BuildContext context) {
      return StreamBuilder<AuthState>(
          stream: data.authStream,
          initialData: AuthState(data.model),
          builder: (context, snapshot) {
            AuthState ds = snapshot.data;

            return  Scaffold(
                  appBar: MyAppbar(
                    //leading: Icon(Icons.arrow_back, color: Colors.white,),
                    title: Text(widget.title,
                        style: TextStyle(color: Colors.white, fontSize: 20)),
//                    startColor: Color.fromRGBO(3, 5, 9, 1.0),
//                    endColor: Color.fromRGBO(32, 56, 100, 1.0),
                  ),
                  body: SafeArea(
                    child: FormBuilder(
                      key: _fbKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          AnimatedList(
                          key: _myListKey,
                          initialItemCount: 3,
                          itemBuilder: (BuildContext context, int index,
                              Animation<double> animation) {
                            return SlideTransition(
                                position: Tween<Offset>(begin: Offset(0.0, -1.0),
                                    end: Offset(0.0, 0.0)).animate(animation),
                                child: list[index]
                            );
                          },

                        ).EXPANDED(),
                          RaisedButton(
                            child: Text('SUBMIT'),
                            onPressed: () {
                              if(_fbKey.currentState.saveAndValidate())
                              {
                                OnDetailsSubmitted(_fbKey.currentState.value, ds.data.user);
                              }
                            },

                          )
                        ],
                      ),
                    ).MY_BACKGROUND_CONTAINER(),
                  )


              );
          }
      );
    }



}
