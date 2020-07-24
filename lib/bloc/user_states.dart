import 'package:edojo/classes/data_model.dart';

class UserState{
  DataModel model;
  UserState(this.model);
}

class HelloUserState extends UserState {
  HelloUserState(DataModel model) : super(model);
}
