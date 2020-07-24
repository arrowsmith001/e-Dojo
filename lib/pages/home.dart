
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_states.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/pages/schemes.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:edojo/widgets/extensions.dart';

import '../main.dart';

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

          if(ds is LogOutState)
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

class _HomeDefaultState extends State<HomeDefault> {

  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

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
              appBar: MyAppbar(
                //leading: Icon(Icons.arrow_back, color: Colors.white,),
                title: Text(
                    'Welcome ${ds.data.user.displayName}',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                startColor: Color.fromRGBO(3, 5, 9, 1.0),
                endColor: Color.fromRGBO(32, 56, 100, 1.0),
              ),
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[

                      GridView.count(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        children: <Widget>[

                          BigMainButton(context, Empty(), Colors.yellow).padding(EdgeInsets.all(20.0)),
                          BigMainButton(context, Empty(), Colors.blue).padding(EdgeInsets.all(20.0)),
                          BigMainButton(context, GoToSchemes(), Colors.pink, title: 'Scheme Editor').padding(EdgeInsets.all(20.0)),
                          BigMainButton(context, Empty(), Colors.orange).padding(EdgeInsets.all(20.0)),

                        ])

                    ],
                  ),
                ).MY_BACKGROUND_CONTAINER(),
              ),
            );
        });
  }
}


class BigMainButton extends StatelessWidget{
  BigMainButton(this.context0, this.widget, this.color, {this.title});
  final String title;

  BuildContext context0;
  Color color;
  Widget widget;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FlatButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      onPressed: () {

        Navigator.of(context0).push(MaterialPageRoute(builder: (BuildContext context) { return widget; }));
      },
      child: Text(title ?? ''),
      color: color,

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
                    startColor: Color.fromRGBO(3, 5, 9, 1.0),
                    endColor: Color.fromRGBO(32, 56, 100, 1.0),
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
