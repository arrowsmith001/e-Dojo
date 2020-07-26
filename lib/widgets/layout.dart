import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:edojo/widgets/extensions.dart';
//
//class MyAppBar2 extends AppBar{
//
//
//
//}
//
//class MyAppbar extends StatelessWidget implements PreferredSizeWidget {
//  MyAppbar({Key key, this.title, this.startColor, this.endColor, this.leading, this.trailing}) : super(key: key);
//
//  final Widget title;
//  final Widget leading;
//  final Widget trailing;
//  final Size preferredSize = const Size.fromHeight(kToolbarHeight);
//
//  final Color startColor;
//  final Color endColor;
//
//
//  @override
//  Widget build(BuildContext context) {
//    final ScaffoldState scaffold = Scaffold.of(context, nullOk: true);
//    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
//
//    final bool hasDrawer = scaffold?.hasDrawer ?? false;
//    final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;
//    final bool canPop = parentRoute?.canPop ?? false;
//    final bool useCloseButton = parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;
//
//    return Material(
//      elevation: 26.0,
//      color: Colors.white,
//      child: Container(
//        padding: const EdgeInsets.all(10.0),
//        alignment: Alignment.centerLeft,
//        decoration: BoxDecoration(
//          gradient: LinearGradient(
//            begin: AlignmentDirectional.topCenter,
//            end: AlignmentDirectional.bottomCenter,
//            colors: [
//              Color.fromRGBO(3, 5, 9, 1.0),
//              Color.fromRGBO(32, 56, 100, 1.0),
//            ]
//        ),
//          border: Border(
//            bottom: BorderSide(
//              color: Colors.white,
//              width: 3.0,
//              style: BorderStyle.solid,
//            ),
//          ),
//        ),
//        child: Row(
//          children: [
//            leading == null ? Container(width: 0, height: 0)
//            : Padding(
//              padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 4.0),
//              child: Container(child: leading, alignment: Alignment.bottomLeft,),
//            ),
//            Padding(
//              padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 2.0),
//              child: Container(child: title, alignment: Alignment.bottomLeft,),
//            ),
//            Container().EXPANDED(),
//            trailing == null ? Container(width: 0, height: 0)
//                : Padding(
//              padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 4.0),
//              child: Container(child: trailing, alignment: Alignment.bottomRight,),
//            ),
//          ],
//        )
//
//        ,
//      ),
//    );
//  }
//
//}