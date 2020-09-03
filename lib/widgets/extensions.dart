import 'package:flutter/cupertino.dart';

extension WidgetModifier on Widget {
  Widget padding([EdgeInsetsGeometry value = const EdgeInsets.all(16)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }

  Widget EXPANDED(){
    return Expanded(
        child : this
    );
  }

  Widget FLEXIBLE(){
    return Flexible(
        child : this
    );
  }

  Widget FLEX(int flex){
    return Flexible(
        flex: flex,
        child : this
    );
  }

  Widget BORDER(Color color, double width){
    return Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: width)),
        child : this
    );
  }

  Widget SIZED({double width, double height}){
    return SizedBox(
        width: width,
        height: height,
        child : this
    );
  }

  Widget FITTED(BoxFit fit){
    return FittedBox(
        fit: fit,
        child : this
    );
  }

  Widget MY_BACKGROUND_CONTAINER()
  {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: [
                Color.fromRGBO(3, 5, 9, 1.0),
                Color.fromRGBO(29, 50, 89, 1.0),
                Color.fromRGBO(29, 50, 89, 1.0),
                Color.fromRGBO(3, 5, 9, 1.0),
               // Color.fromRGBO(3, 5, 9, 1.0),
              ],
              stops: [
                0,
                0.25,
                 0.75,
                 1,
                //1
              ]
          )
      ),
      child: this,
    );
  }
}