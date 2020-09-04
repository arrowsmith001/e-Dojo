//import 'dart:html';
import 'dart:io';

import 'package:edojo/widgets/my_app_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:edojo/bloc/appstate_events.dart';
import 'package:edojo/bloc/appstate_states.dart';
import 'package:edojo/bloc/bloc.dart';
import 'package:edojo/bloc/auth_states.dart';
import 'package:edojo/classes/data_model.dart';
import 'package:edojo/tools/assets.dart';
import 'package:edojo/tools/network.dart';
import 'package:edojo/tools/storage.dart';
import 'package:edojo/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:edojo/classes/misc.dart';
import 'package:edojo/widgets/extensions.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_form_builder/src/widgets/image_source_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';

class SchemesPage extends StatefulWidget {
  @override
  _SchemesPageState createState() => _SchemesPageState();
}

class _SchemesPageState extends State<SchemesPage> with SingleTickerProviderStateMixin {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    data.appStateEventSink.add(RefreshSchemesEditingAndOwned());

    _tabController = TabController(vsync: this, length: 2);

  }

  void NavigateToNewSchemeEdit(NewGameInfo info) {
    data.appStateEventSink.add(StartNewSchemeEditEvent(info));
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return SchemeEditor(data.appStateStream);
        })).then((value) {
      data.appStateEventSink.add(RefreshSchemesEditingAndOwned());
    });
  }



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateState>(
        stream: data.appStateStream,
        initialData: AppStateState(data.model),
        builder: (context, snapshot) {
          AppStateState ds = snapshot.data;
          DataModel dm = ds.model;



          return Scaffold(
              appBar:
              MyAppbar(
                title: Text('Schemes', style: TextStyle(color: Colors.white),),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: <Widget>[
                  Tab(text: 'My Schemes',),
                  Tab(text: 'Editor')
                ],),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => PublishedSchemeBrowser()))
                          .then((value) {
                        data.appStateEventSink.add(RefreshSchemesEditingAndOwned());
                      });
                    },)
                ],
              )
//              MyAppbar(
//                //leading: Icon(Icons.arrow_back, color: Colors.white,),
//                title: Text(
//                    'Schemes',
//                    style: TextStyle(color: Colors.white, fontSize: 20)),
//                startColor: Color.fromRGBO(3, 5, 9, 1.0),
//                endColor: Color.fromRGBO(32, 56, 100, 1.0),
//              )
            ,
              body: SafeArea(
                child: Center(
//              child: Column(
//                mainAxisSize: MainAxisSize.min,
//                children: <Widget>[
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    Center(child:
                      dm.schemesOwned == null || dm.schemesOwned.isEmpty
                          ? Text('No schemes owned')
                          : ListView.builder(
                          itemCount: dm.schemesOwned.length,
                          itemBuilder: (context, i){
                            SchemeMetadata meta = dm.schemesOwned[i];
                            return ListTile(
                              leading: meta.GetGameImage(),
                              title: Text(meta.gameName),
                              trailing: IconButton(
                                icon: Icon(Icons.arrow_forward_ios, color: Colors.white,),
                                onPressed: () {  },),
                            );

                          })
                    ),
                    Column(
                        children:[
                          ds.model.schemesEditing.length == 0 ? Center(child: Text('You have no schemes in the editor')) :
                          ListView.builder(
                              itemCount: ds.model.schemesEditing.length,
                              itemBuilder: (context, i) {

                                return ListTile(
                                  leading: ds.model.schemesEditing[i].GetGameImage(),
                                  title: Text(ds.model.schemesEditing[i].gameName),
                                  trailing: IconButton(icon: Icon(Icons.edit, color: Colors.white,),onPressed: () {

                                    data.appStateEventSink.add(StartNewSchemeEditEvent.resume(ds.model.schemesEditing[i]));
                                    Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                          return SchemeEditor(data.appStateStream);
                                        })).then((value) {
                                      data.appStateEventSink.add(RefreshSchemesEditingAndOwned());
                                    });

                                  },),
                                );

                              }).EXPANDED(),

                          RaisedButton(onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute<NewGameInfo>(builder: (context) => NewGameDialog()))
                                .then((value) => value == null ? null : NavigateToNewSchemeEdit(value));
                          },
                            child: Text('GO TO SCHEME EDITOR'),)


                        ]
                    )
                  ],

                )
                    //SchemeRepresentationTest().padding(EdgeInsets.all(15))



//                ],
//              ),
                ).MY_BACKGROUND_CONTAINER(),
              ),
            )
          ;
        });
  }
}

class SchemeQueryInfo{
  SchemeQueryInfo(this.numberOfDocuments, this.orderBy, this.descending, this.reset);
  int numberOfDocuments;
  String orderBy;
  bool descending;

  /// Reset current query results OR add to current results
  bool reset;
}

class PublishedSchemeBrowser  extends StatefulWidget {

  @override
  _PublishedSchemeBrowserState createState() => _PublishedSchemeBrowserState();
}

class _PublishedSchemeBrowserState extends State<PublishedSchemeBrowser> {

  DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  @override
  void initState() {
    print('_PublishedSchemeBrowserState initState called');
    super.initState();
    data.appStateEventSink.add(QueryForPublishedSchemes(new SchemeQueryInfo(10, 'upvotes', true, true)));
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AppStateState>(
      initialData: AppStateState(data.model),
      stream: data.appStateStream,
      builder: (context, snapshot) {

        DataModel model = snapshot.data.model;

        return SafeArea(
          child: Scaffold(
            appBar: MyAppbar(
              title: Text('Browse published schemes')
            ),
            body: Container(

              child: model.schemesInShopBrowser.length == 0 ? Text('No results')
              : ListView.builder(
                  itemCount: model.schemesInShopBrowser.length,
                  itemBuilder: (context, i){

                    SchemeMetadata meta = model.schemesInShopBrowser[i];

                    return ListTile(
                      leading: meta.GetGameImage(),
                      title: Text(meta.gameName),
                      subtitle: Text('Upvotes: ${meta.upvotes}'),
                      trailing: model.isSchemeOwned(meta.schemeID)
                          ? Icon(Icons.check, color: Colors.white,)
                          : IconButton(
                        icon: Icon(Icons.file_download, color: Colors.white),
                        onPressed: () {
                          data.appStateEventSink.add(SchemeDownloaded(meta));
                        },),
                );
              })

            ).MY_BACKGROUND_CONTAINER(),
          ),
        );
      }
    );

  }
}




class NewGameInfo {
  NewGameInfo(this.name, this.nickname, this.icon);
  String name;
  String nickname;
  File icon;
}


class SchemeEditor extends StatefulWidget{

  SchemeEditor(this.appStateStream);
  Stream<AppStateState> appStateStream;

  @override
  _SchemeEditorState createState() => _SchemeEditorState();
}

class _SchemeEditorState extends State<SchemeEditor> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  PageController _controller;

  void initState(){
    super.initState();
    _controller = new PageController(initialPage: data.model.schemeEditorState.schemeEditorPageNum);
    page = data.model.schemeEditorState.schemeEditorPageNum;

  }

  int page = 0;
  void ChangePage() {

    setState(() {

      _controller.animateToPage((page == 0 ? 1 : 0), duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    page = page == 1 ? 0 : 1;

    data.appStateEventSink.add(SchemeEditorPageChanged(page));

    });
  }

  void EditGridDimensions(DataModel model, Ops op, GridOps grid) {

    setState(() {
      model.schemeEditorState.SchemeEditorGridOperation(op, grid);
    });
  }

  void AddOrEditFighter(Square square) {

    showDialog(context: context, builder: (context) {
      return NewPlayerDialog(square);
    });
   // appState.appStateEventSink.add(StartNewSchemeEditEvent('New Game','NG'));

  }

  void SaveThisScheme(User user, GameScheme scheme) {

    net.SaveSchemeToEdits(user, scheme);


  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AppStateState>(
      initialData: AppStateState(data.model),
      stream: widget.appStateStream,
      builder: (context, snapshot) {

        DataModel model = snapshot.data.model;
        User user = model.user;
        GameScheme scheme = model.schemeEditorState.schemeInEditor;

        bool swapMode = model.schemeEditorState.swapMode;
        String swapString = 'Select a cell to swap with';
        String fighterString = model.schemeEditorState.GetFighterAtSelectionString();

        Square square = model.schemeEditorState.GetSelection();

        bool ready = model != null && scheme != null && square != null;

        if(!ready) return Center(child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator(),),);

        return Scaffold(
          appBar: MyAppbar(
            leading: Icon(Icons.arrow_back, color: Colors.white,),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.save, color: Colors.white,), onPressed: () { SaveThisScheme(model.user, scheme); },)
            ] ,
            title: Text(
                scheme == null ? '' : scheme.meta.gameName,
                style: TextStyle(color: Colors.white, fontSize: 20)),
//            startColor: Color.fromRGBO(3, 5, 9, 1.0),
//            endColor: Color.fromRGBO(32, 56, 100, 1.0),
          ),
          body: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2, color: Colors.white))),
                    child: PageView(
                      controller: _controller,
                      physics: NeverScrollableScrollPhysics(),
                        children:
                            [
                              scheme == null || scheme.GetRosterLength() == 0 ? Center(child: Text('No fighters added'))
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: scheme.GetRosterLength(),
                                  itemBuilder: (context, i) {


                                return ListTile(
                                  title: Text(scheme.roster[i] == null ? '' : scheme.roster[i].fighterName),
                                  leading: SizedBox(height: 50, width: 50, child: FittedBox(fit: BoxFit.fill,
                                      child: scheme.roster[i].GetFighterImage()
                                  )),
                                );
                              }),

                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                  Row(
                                    children: [
                                      FighterTableFromScheme(scheme).EXPANDED(),
                                      Container(width: 50, child: Column(mainAxisSize: MainAxisSize.min, children: [
                                        Container().EXPANDED(),
                                        IconButton(onPressed: () { EditGridDimensions(model, Ops.remove, GridOps.row); }, icon: Icon(Icons.remove, color: Colors.white,)),
                                        IconButton(onPressed: () { EditGridDimensions(model, Ops.add, GridOps.row); }, icon: Icon(Icons.add, color: Colors.white)) ])//.FLEXIBLE()
                                      )
                                    ],
                                  ).FLEXIBLE()
                                    ,
                                  Container(
                                    height: 50,
                                    child: Flex(
                                      direction: Axis.vertical,
                                      children: [Row(
                                        children: <Widget>[
                                          Row(mainAxisSize: MainAxisSize.min, children: [
                                            Container(height: 50, child:
                                            Text(swapMode ? swapString : fighterString, textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: swapMode ? Colors.purpleAccent : Colors.white,))).EXPANDED(),
                                            IconButton(onPressed: () { EditGridDimensions(model, Ops.remove, GridOps.column); }, icon: Icon(Icons.remove, color: Colors.white)),
                                            IconButton(onPressed: () { EditGridDimensions(model, Ops.add, GridOps.column); }, icon: Icon(Icons.add, color: Colors.white)) ]).FLEXIBLE()
                                          ,
                                          Container(height: 50, width: 50)
                                        ],
                                      ).FLEXIBLE()
                                      ],
                                    )
                                    ,
                                  )
                                ],)
                ]),
                  ).FLEX(2),

                 Container(
                   height: 100,
                   child: Column(
                     children: <Widget>[
                       Row(
                           children:[
                             Container(child: scheme == null ? Empty() : scheme.GetGameImage()).FLEXIBLE(),
                             RaisedButton(
                               child: Text(page == 0 ? 'Grid view' : 'List view'),
                               onPressed: () {
                                 ChangePage();
                               },

                             ),
                             RaisedButton(
                               child: Text(square.fighter == null ? 'Add Fighter' : 'Edit Fighter'),
                               onPressed: () {
                                 AddOrEditFighter(square);
                               },

                             ),
                           ]
                       ).FLEXIBLE(),

                       RaisedButton(
                         child: Text('Upload'),
                         onPressed: () {
                           net.UploadScheme(user, scheme);
                         },

                       )


                     ],
                   ),
                 ).FLEX(0),

              ],
            )
          ).MY_BACKGROUND_CONTAINER(),
        );
      }
    );
  }



}

class NewGameDialog extends StatefulWidget {
  NewGameDialog();

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  void initState()
  {
    super.initState();
  }

  Future<void> OnNewSchemeEditStartedDetailsSaved(Map<String, dynamic> map) async {

    List list = map['Icon'];
    File file = (list == null || list.isEmpty ? null : list[0]);
    Navigator.of(context).pop(NewGameInfo(map['Name'], map['Nickname'], file));
  }

  String helperText1 = 'The name of this game.';
  String helperText2 = 'A short identifier/abbreviation of this game\'s name.';
  String helperText3 = 'An icon to associate with your game.';

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: Color.fromRGBO(29, 50, 89, 1.0),
      title: Text('New Game'),
      content: FormBuilder(
          key: _fbKey,
          // autovalidate: _resetValidate,
          child: SingleChildScrollView(
            physics: ScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:<Widget>[
                FormBuilderTextField(
                    attribute: 'Name',
                    initialValue: '',
                    decoration: InputDecoration(
                        labelText: 'Name',
                        helperText: helperText1,
                        filled: true, fillColor: Color.fromRGBO(0, 0, 0, 0)),
                    validators: [
                      FormBuilderValidators.required(errorText:'Required field')
                    ]
                ),
                Padding(padding: EdgeInsets.all(10),),
                FormBuilderTextField(
                    attribute: 'Nickname',
                    initialValue: '',
                    decoration: InputDecoration(
                        labelText: 'Nickname',
                        helperText: helperText2,
                        filled: true, fillColor: Color.fromRGBO(0, 0, 0, 0)),
                    validators: [
                      FormBuilderValidators.required(errorText:'Required field')
                    ]
                ),
                Padding(padding: EdgeInsets.all(10),),
                FormBuilderImagePicker(
                  initialValue: [],
                  maxImages: 1,
                  imageWidth: 50,
                  imageHeight: 50,
                  decoration: InputDecoration(filled: true, fillColor: Color.fromRGBO(0, 0, 0, 0), helperText: helperText3),
                  labelText: 'Icon (optional)',
                  attribute: 'Icon',
                ),


              ],
            ),
          )
      )

      ,

      actions: <Widget>[
        new FlatButton(
          child: new Text(
            'CANCEL',
          ),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        new FlatButton(
          child: new Text(
            'ADD',
          ),
          onPressed: () {
            if (_fbKey.currentState.saveAndValidate()) {
              Map<String, dynamic> map = _fbKey.currentState.value;
              OnNewSchemeEditStartedDetailsSaved(map);
            }
          },
        ),
      ],
    );
  }



}



class NewPlayerDialog extends StatefulWidget {
  NewPlayerDialog(this.square);

  Square square;

  @override
  _NewPlayerDialogState createState() => _NewPlayerDialogState();
}

class _NewPlayerDialogState extends State<NewPlayerDialog> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  void initState()
  {
    super.initState();
    variantNum = widget.square.fighter == null || widget.square.fighter.variants == null ? 0 : widget.square.fighter.variants.length;
  }

  String helperText = 'List any variations/equippable items that a fighter can take into battle.';
  int variantNum;

  void ChangeListNum(int to)
  {
    setState(() {
      variantNum = to;
      print('listfieldNum changed to $to');
    });
  }

  Future<void> ProcessFighterForm(Map<String, dynamic> map) async {

    if(widget.square.fighter == null) data.appStateEventSink.add(FighterAddedToSchemeEvent(map));
    else {data.appStateEventSink.add(FighterEditedInSchemeEvent(widget.square.fighter, map));}

    Navigator.of(context).pop("");
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: Color.fromRGBO(29, 50, 89, 1.0),
          title: Text(widget.square.fighter == null ? 'New Fighter' : 'Edit ${widget.square.fighter.fighterName}'),
          content: FormBuilder(
              key: _fbKey,
              // autovalidate: _resetValidate,
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:<Widget>[
                    FormBuilderTextField(
                        attribute: 'Name',
                        initialValue: widget.square.fighter == null ? '' : widget.square.fighter.fighterName,
                        decoration: InputDecoration(
                            labelText: 'Name',
                            helperText: 'This fighter\'s name.',
                        filled: true, fillColor: Color.fromRGBO(0, 0, 0, 0)),
                        validators: [
                          FormBuilderValidators.required(errorText:'Required field')
                        ]
                    ),
                    Padding(padding: EdgeInsets.all(10),),
                    FormBuilderImagePicker(
                      initialValue: widget.square.fighter == null || widget.square.fighter.iconImgFile == null ? [] : [widget.square.fighter.iconImgFile],
                      maxImages: 1,
                      imageWidth: 50,
                      imageHeight: 50,
                      decoration: InputDecoration(filled: true, fillColor: Color.fromRGBO(0, 0, 0, 0), helperText: 'Image that identifies this fighter.'),
                      labelText: 'Icon (optional)',
                      attribute: 'Icon',

                    ),
                    Padding(padding: EdgeInsets.all(10),),
                    ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 1,
                        itemBuilder: (context, i) {
                          return Container(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children:[
                                        FormBuilderTouchSpin(
                                            onChanged: (value) { ChangeListNum(value); },
                                            min: 0,
                                            step: 1,
                                            initialValue: variantNum,
                                            attribute: 'Variations',
                                            decoration: InputDecoration(
                                              filled: true,
                                                fillColor: Color.fromRGBO(0, 0, 0, 0),
                                                labelText: ('Variations (optional)'),
                                                helperText: variantNum == 0 ? helperText : null ,
                                                helperMaxLines: 3),
                                            validators: [
                                              (dynamic) => null
                                            ]
                                        ),
                                        ListView.builder(
                                            physics: NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: variantNum,
                                            itemBuilder: (context, j) {
                                              return FormBuilderTextField(
                                                initialValue: widget.square.fighter == null || widget.square.fighter.variants == null ? '' : widget.square.fighter.variants[j],
                                                attribute: 'Variant$j',
                                                decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: Colors.transparent,
                                                    labelText: '${j + 1}',
                                                    helperText: j + 1 == variantNum ? helperText : null,
                                                    helperMaxLines: 3),
                                                validators: [
                                                  FormBuilderValidators.required(errorText:'List item should be filled or removed')
                                                ],
                                              );
                                            }
                                        ),
                                      ]
                                  )
                                ]
                            ),
                          );
                        }),


                  ],
                ),
              )
          )

          ,

          actions: <Widget>[
            new FlatButton(
              child: new Text(
                'CANCEL',
              ),
              onPressed: () {
                Navigator.of(context).pop("");
              },
            ),
            new FlatButton(
              child: new Text(
                widget.square.fighter == null ? 'ADD' : 'SAVE',
              ),
              onPressed: () {
                if (_fbKey.currentState.saveAndValidate()) {
                  Map<String, dynamic> map = _fbKey.currentState.value;

                  ProcessFighterForm(map);
                }
              },
            ),
          ],
        );
  }

}








class FighterTableFromScheme extends StatefulWidget {

  FighterTableFromScheme(this.scheme);
  final GameScheme scheme;

  @override
  _FighterTableFromSchemeState createState() => _FighterTableFromSchemeState();
}

class _FighterTableFromSchemeState extends State<FighterTableFromScheme> {
  final DataBloc data = BlocProvider.instance.dataBloc;
  final NetworkServices net = NetworkServiceProvider.instance.netService;

  final _scrollController = new ScrollController(keepScrollOffset: false);
  final _scrollController2 = new ScrollController(keepScrollOffset: false);

  List<TableRow> tableRows;

  double boxDim = 50;
  double localScale = 1;
  double boxDimTemp = 50;

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

  void HandleTap(int i, int j) {
    data.appStateEventSink.add(SchemeEditorCellPressedEvent(new GridSelection.init(i, j)));
  }

  void HandleLongPress(int i, int j) {
    data.appStateEventSink.add(SchemeEditorCellHeldEvent(new GridSelection.init(i, j)));
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
            // OPTION 1: Text representation
            Widget textWidget = FittedBox(
                fit: BoxFit.fitHeight,
                child: AutoSizeText(widget.scheme.grid.getSquare(i, j).GetName())
            );

            // OPTION 2: Image representation
            Widget imgWidget = FittedBox(
              fit: BoxFit.fill,
                child: widget.scheme.grid.getSquare(i, j).GetImage(0.3)
            );

           rowContents.add(
               StreamBuilder<AppStateState>(
                 initialData: AppStateState(data.model),
                 stream: data.appStateStream,
                 builder: (context, snapshot) {

                   DataModel model = snapshot.data.model;

                   return GestureDetector(
                     onLongPress: () {HandleLongPress(i, j);},
                     onTap: () { HandleTap(i, j); },
                     child:
                     SizedBox(
                          width: boxDim,
                         height: boxDim,
                          child: (model.schemeEditorState.schemeEditorGridSelection.compare(i, j) ?
                          imgWidget.BORDER(model.schemeEditorState.swapMode ? Colors.purpleAccent : Colors.yellow, 3.0) : imgWidget).PADDING(EdgeInsets.all(2))
                     ),
                   );
                 }
               )
           );
          }
        tableRows.add(new TableRow(
          children: rowContents
        ));
      }


    return
      FutureBuilder<Image>(
        builder: (context,snapshot) {

          return GestureDetector(
            onScaleUpdate: (details){
              localScale = details.scale;
              ChangeDim(localScale * boxDimTemp, false);
            },
            onScaleEnd: (details) {
              ChangeDim(localScale * boxDimTemp, true);
              localScale = 1;
            },
            child: Scrollbar(
                controller: _scrollController2,
                child: ListView(
                    children: <Widget>[
                      SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child:
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Center(child:

                              Container(
                                child: Table(
                                    defaultColumnWidth: IntrinsicColumnWidth(),
                                    children: tableRows
                                ),
                              )

                              ),
                            ],
                          )
                      )
                    ])),
          );
        },
      )
    ;

  }



}


