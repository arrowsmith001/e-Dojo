
import 'package:edojo/classes/data_model.dart';

class AuthState {
  AuthState(this.data);
  DataModel data;
}

class LoggedInState extends AuthState{
  LoggedInState(DataModel data) : super(data);

}

class LoggingInState extends AuthState{
  LoggingInState(DataModel data) : super(data);

}

class LoginFailedState extends AuthState{
  LoginFailedState(DataModel data, this.msg) : super(data);
  final String msg;

}

class SigningUpState extends AuthState{
  SigningUpState(DataModel data) : super(data);

}
class SignUpFailedState extends AuthState{
  SignUpFailedState(DataModel data, this.msg) : super(data);
  final String msg;

}
class DeterminingProfileCompletionState extends AuthState{
  DeterminingProfileCompletionState(DataModel data) : super(data);

}

class LogOutState extends AuthState{
  LogOutState(DataModel data) : super(data);

}
