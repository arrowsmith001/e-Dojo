import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_states.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:edojo/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:edojo/widgets/extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:gradient_app_bar/gradient_app_bar.dart';

import 'package:edojo/widgets/my_app_bar.dart';
import 'bloc/auth_events.dart';
import 'pages/home.dart';

void main() {

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: TextTheme(
          headline1: TextStyle(color: Colors.white),
          headline2: TextStyle(color: Colors.white),
          headline3: TextStyle(color: Colors.white),
          headline4: TextStyle(color: Colors.white),
          headline5: TextStyle(color: Colors.white),
          headline6: TextStyle(color: Colors.white),
          subtitle1:TextStyle(color: Colors.white),
          subtitle2: TextStyle(color: Colors.white),
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
          caption: TextStyle(color: Colors.white),
          button:TextStyle(color: Colors.white),
          overline: TextStyle(color: Colors.white),
        ),
        primarySwatch: Colors.blue,
        accentColor: Colors.white,
        highlightColor: Colors.white,
        hintColor: Colors.white,
        splashColor: Colors.white,
        cursorColor: Colors.white,
        dividerColor: Colors.white,
        primaryColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RootPage(title: 'Welcome to e-Dojo'),
      routes: <String,WidgetBuilder>{
        '/signin' : (context) => SignInPage(),
        '/signup' : (context) => SignUpPage(),
        '/home' : (context) => HomePage(),
        '/root' : (context) => RootPage(title: 'Welcome to e-Dojo')
      },
    );
  }
}


class RootPage extends StatefulWidget {
  RootPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {

  final NetworkServices net = NetworkServiceProvider.instance.netService;
  final DataBloc data = BlocProvider.instance.dataBloc;

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AuthState>(
        stream: data.authStream,
        initialData: AuthState(data.model),
        builder: (context, snapshot) {
          AuthState ds = snapshot.data;



          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child:
                  ds is LogOutState ? RootDefault(widget.title)
                  : ds is LoggingInState || ds is SigningUpState || ds is SignUpFailedState || ds is DeterminingProfileCompletionState ? Loading()
                  : HomePage()
          );
        });
  }
}

class RootDefault extends StatelessWidget {
  RootDefault(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
          appBar: MyAppbar(
            //leading: Icon(Icons.arrow_back, color: Colors.white,),
            title: Text(title,
                style: TextStyle(color: Colors.white, fontSize: 20)),
//            startColor: Color.fromRGBO(3, 5, 9, 1.0),
//            endColor: Color.fromRGBO(32, 56, 100, 1.0),
          ),
          body: SafeArea(
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container().EXPANDED(),
                    RaisedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signin');
                      },
                      child: Text('SIGN IN'),
                    ),
                    RaisedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text('SIGN UP'),
                    ),
                  ]),
            ).MY_BACKGROUND_CONTAINER(),
          )
    );
  }

}

class Loading extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: SizedBox(
          height: 50, width: 50,
          child: CircularProgressIndicator()),
    );
  }

}

class SignInPage extends StatelessWidget {

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final NetworkServices net = NetworkServiceProvider.instance.netService;
  final DataBloc data = BlocProvider.instance.dataBloc;

  final String title = 'Sign in';

  void OnSignInFormSubmit(Map<String, dynamic> map) {

    print('Attempting sign-in with ${map['Email']} ${map['Password']}');
    net.SignIn(map['Email'], map['Password']);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: data.authStream,
      initialData: AuthState(data.model),
      builder: (context, snapshot) {

        AuthState ds = snapshot.data;

        if(ds is LoggedInState) {

          //print('LogInState received by RootPage');
          Navigator.pop(context);
        }

        bool loggingIn = (ds is LoggingInState);

        return Scaffold(
              appBar: MyAppbar(
                leading: IconButton(icon: Icon(Icons.arrow_back), color: Colors.white, onPressed: () { Navigator.of(context).pop(); },),
                title: Text(title, style: TextStyle(color:Colors.white, fontSize: 20)),
//                startColor: Color.fromRGBO(3, 5, 9, 1.0),
//                endColor: Color.fromRGBO(32, 56, 100, 1.0),
              ),
              body: SafeArea(
                child: FormBuilder(
                  key: _fbKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[

                        FormBuilderTextField(
                            attribute: 'Email',
                            initialValue: '',
                            decoration: InputDecoration(labelText: 'Email', filled: true),
                            validators: [
                              FormBuilderValidators.required(errorText:'Required field')
                            ]
                        ).PADDING(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),

                        FormBuilderTextField(
                          obscureText: true,
                            maxLines: 1,
                            attribute: 'Password',
                            initialValue: '',
                            decoration: InputDecoration(labelText: 'Password', filled: true),
                            validators: [
                              FormBuilderValidators.required(errorText:'Required field')
                            ]
                        ).PADDING(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),

                        RaisedButton(
                          child: Text(loggingIn ? '...' : 'SIGN IN'),
                          onPressed: () {
                            if (_fbKey.currentState.saveAndValidate()) {

                              OnSignInFormSubmit(_fbKey.currentState.value);
                            }
                          },
                        ),
                        Center(
                          child: SizedBox(
                              height: 50, width: 50,
                              child: loggingIn ? CircularProgressIndicator() : Container())
                        )

                      ]
                  ),
                )
                    .MY_BACKGROUND_CONTAINER(),
              )
          );
      }
    );
  }
}

class SignUpPage extends StatelessWidget {

  final String title = 'Sign up';

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final NetworkServices net = NetworkServiceProvider.instance.netService;
  final DataBloc data = BlocProvider.instance.dataBloc;

  void OnSignUpFormSubmit(Map<String, dynamic> map) {

    print('Attempting sign-up with ${map['Email']} ${map['Password']}');
    net.CreateUser(map['Email'], map['Password']);

  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
        stream: data.authStream,
        initialData: AuthState(data.model),
        builder: (context, snapshot) {

          AuthState ds = snapshot.data;

          if(ds is LoggedInState) {

            //print('LogInState received by RootPage');
            Navigator.pop(context);
          }

          bool loggingIn = (ds is LoggingInState || ds is SigningUpState);
          String errorMsg = ds is SignUpFailedState ? ds.msg : null;

          return Scaffold(
              appBar: MyAppbar(
                leading: IconButton(icon: Icon(Icons.arrow_back), color: Colors.white, onPressed: () { Navigator.of(context).pop(); },),
                title: Text(title, style: TextStyle(color:Colors.white, fontSize: 20)),
//                startColor: Color.fromRGBO(3, 5, 9, 1.0),
//                endColor: Color.fromRGBO(32, 56, 100, 1.0),
              ),
              body: SafeArea(
                child: FormBuilder(
                  key: _fbKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[

                        FormBuilderTextField(
                            attribute: 'Email',
                            initialValue: '',
                            decoration: InputDecoration(labelText: 'Email', filled: true),
                            validators: [
                              FormBuilderValidators.required(errorText:'Required field')
                            ]
                        ).PADDING(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),

                        FormBuilderTextField(
                            obscureText: true,
                            maxLines: 1,
                            attribute: 'Password',
                            initialValue: '',
                            decoration: InputDecoration(labelText: 'Password', filled: true),
                            validators: [
                              FormBuilderValidators.required(errorText:'Required field')
                            ]
                        ).PADDING(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),

                        FormBuilderTextField(
                            obscureText: true,
                            maxLines: 1,
                            attribute: 'Confirm password',
                            initialValue: '',
                            decoration: InputDecoration(labelText: 'Confirm password', filled: true),
                            validators: [
                              FormBuilderValidators.required(errorText:'Required field')
                            ]
                        ).PADDING(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),

                        RaisedButton(
                          child: Text(loggingIn ? '...' : 'SIGN UP'),
                          onPressed: () {
                            if (_fbKey.currentState.saveAndValidate()) {

                              Map<String, dynamic> map = _fbKey.currentState.value;

                              if(map['Password'] != map['Confirm password'])
                                {
                                  data.authEventSink.add(SignUpFailedEvent('Password fields don\'t match'));
                                }
                              else
                                {
                                  OnSignUpFormSubmit(_fbKey.currentState.value);
                                }
                            }
                          },
                        ),
                        Center(
                            child: SizedBox(
                                height: 50, width: 50,
                                child: loggingIn ? CircularProgressIndicator() : Container())
                        ),

                        errorMsg == null ? Empty()
                            : Text(errorMsg, style: TextStyle(color: Theme.of(context).errorColor))

                      ]
                  ),
                )
                    .MY_BACKGROUND_CONTAINER(),
              ));
        }
    );
  }
}

class Empty extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
   return SizedBox(height: 0, width: 0,);
  }

}
