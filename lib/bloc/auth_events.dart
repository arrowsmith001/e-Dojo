import 'package:edojo/classes/misc.dart';

import 'bloc.dart';

class AuthEvent extends BlocEvent {}

class LogInEvent extends AuthEvent {
  LogInEvent(this.user);
  User user;
}

class LoggingInEvent extends AuthEvent {
}

class LoginFailedEvent extends AuthEvent{
  LoginFailedEvent(this.msg);
  String msg;
}

class SigningUpEvent extends AuthEvent {
}

class SignUpFailedEvent extends AuthEvent{
  SignUpFailedEvent(this.msg);
  final String msg;
}

class LogOutEvent extends AuthEvent{

}

class DeterminingProfileCompletionEvent extends AuthEvent{

}

class ProfileComplete extends AuthEvent{

}

class UserJustCreatedEvent extends AuthEvent {
  UserJustCreatedEvent(this.user);
  User user;
}