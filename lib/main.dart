import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Zux Burgers',
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primaryColor: Color(0xff202020),
          accentColor: Color(0xfff83131),
          scaffoldBackgroundColor: Color(0xff202020),
        ),
        home: MyHomePage(
          title: 'Zux Burgers',
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSearch = false;
  final TextEditingController orderSearch = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    // this function needs to run when app starts then upload it to firestore as devices and the date
    firebaseCloudMessaging_Listeners();
  }

// ignore: non_constant_identifier_names
  void firebaseCloudMessaging_Listeners() {
    _firebaseMessaging.subscribeToTopic('burgerOrders');
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        setState(() {
          // _firebaseMessaging.getToken().then((token) {
          //   print("token is: " + token);
          // });
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.20;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Color(0xff202020),
        appBar: AppBar(
          centerTitle: true,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: _isSearch == false
              ? Text(widget.title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontFamily: 'Elephant',
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold))
              : TextField(
                  controller: orderSearch,
                  autofocus: true,
                  cursorColor: Color(0xffff8181),
                  // maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xffcccccc),
                    letterSpacing: 0.7,
                  ),
                  textInputAction: TextInputAction.done,
                  // buildCounter: (BuildContext context, { int currentLength, int maxLength, bool isFocused }) => null,thi
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search Order',
                      hintStyle:
                          TextStyle(color: Color(0xffcccccc), fontSize: 13)),
                ),
          actions: [
            _isSearch == false
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearch = true;
                      });
                    },
                    child: Icon(
                      Icons.search,
                      color: Color(0xffcccccc),
                      size: 25.0,
                      semanticLabel: 'Search For An Order',
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearch = false;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Color(0xffff8181),
                      size: 25.0,
                      semanticLabel: 'Search For An Order',
                    ),
                  ),
          ],
          // backgroundColor: Colors.black26,
          backgroundColor: Color(0xff202020),
          elevation: 0.0,
          bottom: _isSearch == false
              ? TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: Color(0xffff8181),
                  // indicatorPadding: EdgeInsets.fromLTRB(10, 0, 10, 12),
                  indicatorWeight: 2,
                  labelColor: Color(0xffff8181),
                  labelStyle:
                      const TextStyle(color: Color(0xffff8181), fontSize: 13),
                  unselectedLabelColor: Colors.white,
                  unselectedLabelStyle:
                      const TextStyle(color: Colors.white, fontSize: 13),
                  isScrollable: false,
                  tabs: [
                      Tab(
                          icon:
                              Container(child: Center(child: Text('Pending')))),
                      Tab(
                          icon: Container(
                              child: Center(child: Text('Complete')))),
                      Tab(
                          icon:
                              Container(child: Center(child: Text('Message')))),
                      Tab(icon: Container(child: Center(child: Text('Stats')))),
                    ])
              : null,
        ),
        body: _isSearch == false
            ? TabBarView(children: [
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: OrderList(status: '0'),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: OrderList(status: '1'),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: WebMessage(),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Stats(),
                ),
              ])
            : Container(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: SearchList(orderId: orderSearch.text),
              ),
        // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class OrderList extends StatelessWidget {
  final String status;
  const OrderList({
    Key key,
    this.status,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('burgerOrders')
          .where("completed", isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        if (!snapshot.hasData)
          return Center(
              child: new Text(
            'No Orders',
            style: TextStyle(color: Color(0xffcccccc)),
          ));

        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
//        return a loading screen of sorts
            return new SpinKitChasingDots(
              color: Color(0xffff8181),
              size: 50.0,
              duration: Duration(milliseconds: 2000),
            );
          default:
            return new ListView(
              scrollDirection: Axis.vertical,
              children: snapshot.data.docs.map((DocumentSnapshot document) {
                if (snapshot.data.docs != null) {
                  return OrderCard(
                    name: document.data()['name'],
                    phoneNumber: document.data()['phone'],
                    time: DateFormat.jm()
                        .format(document.data()['timestamp'].toDate()),
                    date: DateFormat.yMMMd()
                        .format(document.data()['timestamp'].toDate()),
                    status: document.data()['completed'].toString(),
                    approval: document.data()['approved'].toString(),
                    ordernumber: document.data()['orderNo'],
                    orderItems: document.data()['items'],
                  );
                } else {
                  return new Text('empty');
                }
              }).toList(),
            );
        }
      },
    );
  }
}

class OrderCard extends StatefulWidget {
  final String name;
  final String date;
  final String status;
  final String phoneNumber;
  final String approval;
  final String time;
  final String ordernumber;
  final List<dynamic> orderItems;
  const OrderCard(
      {Key key,
      this.name,
      this.date,
      this.status,
      this.approval,
      this.phoneNumber,
      this.time,
      this.ordernumber,
      this.orderItems})
      : super(key: key);
  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  // String time = formatTimestamp(widget.time);

  String todayDate = DateFormat('MMM d, y').format(DateTime.now());
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.2;
    double hw = MediaQuery.of(context).size.width * 0.3;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Color(0xfffff4f2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.3),
            blurRadius: 3.0, // soften the shadow
            spreadRadius: 5.0, //extend the shadow
            offset: Offset(
              0.3, // Move to right 10  horizontally
              0.5, // Move to bottom 10 Vertically
            ),
          )
        ],
      ),
      margin: EdgeInsets.only(top: 20, bottom: 10),
      padding: EdgeInsets.all(10),
      child: Column(children: <Widget>[
        Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(widget.ordernumber,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xff202020)))
            ]),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Text(widget.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xff202020))),
                ),
                Container(
                  // width: width,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      widget.date == todayDate
                          ? Text('Today',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                  color: Color(0x4f202020)))
                          : Text(widget.date,
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                  color: Color(0x4f202020)))
                    ],
                  ),
                ),
                Container(
                  // width: width,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(widget.time,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                              color: Color(0x4f202020))),
                    ],
                  ),
                ),
              ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Text("No. of Burgers: ",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 13,
                          color: Color(0xff202020))),
                ),
                // Container(
                //   width: width,
                //   child: Center(
                //     child: Text(widget.phoneNumber,
                //         style: TextStyle(
                //             fontWeight: FontWeight.normal,
                //             fontSize: 18,
                //             color: Color(0xff202020))),
                //   ),
                // ),
                Container(
                  // width: width,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(getQty(widget.orderItems),
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                              color: Color(0xff202020))),
                    ],
                  ),
                ),
              ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 10.0),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Text("Phone Number: ",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 13,
                          color: Color(0xff202020))),
                ),
                // Container(
                //   width: width,
                //   child: Center(
                //     child: Text(widget.phoneNumber,
                //         style: TextStyle(
                //             fontWeight: FontWeight.normal,
                //             fontSize: 18,
                //             color: Color(0xff202020))),
                //   ),
                // ),
                Container(
                  // width: width,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(widget.phoneNumber,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                              color: Color(0xff202020))),
                    ],
                  ),
                ),
              ]),
        ),
        Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  showAlertDialog(context, widget.phoneNumber);
                },
                child: Text('Call or Text',
                    style: TextStyle(fontSize: 13, color: Colors.blue)),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ViewOrder(orderID: widget.ordernumber)),
                  );
                },
                color: Color(0xffff8181),
                textColor: Color(0xff202020),
                child: Container(
                    width: 100,
                    height: 35,
                    child: Center(
                        child: Text('View Order',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: Colors.black)))),
              ),
            ]),
      ]),
    );
  }
}

showAlertDialog(BuildContext context, String contact) {
  // set up the buttons
  Widget cancelButton = FlatButton(
    child: Container(
        width: 50, child: Text("Cancel", style: TextStyle(color: Colors.red))),
    onPressed: () {
      Navigator
          // .of(context, rootNavigator: true)
          .pop(context);
    },
  );
  Widget messageButton = FlatButton(
    textColor: Color(0xffcccccc),
    color: Color(0xff202020),
    child: Container(width: 50, child: Center(child: Text("call"))),
    onPressed: () {
      _openAlert("tel:" + contact);
    },
  );
  Widget textButton = FlatButton(
    child: Container(width: 50, child: Text("message")),
    onPressed: () {
      _openAlert("sms:" + contact);
    },
  );
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Contact"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text("Do you wish to contact \n"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(contact, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(" ?")
          ],
        ),
      ],
    ),
    actions: [cancelButton, textButton, messageButton],
    actionsOverflowButtonSpacing: 20.0,
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

_openAlert(url) async {
  // const url = 'tel:0776069961';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class ViewOrder extends StatefulWidget {
  final String orderID;
  const ViewOrder({Key key, @required this.orderID}) : super(key: key);
  @override
  _ViewOrderState createState() => _ViewOrderState();
}

class _ViewOrderState extends State<ViewOrder> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.3;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('burgerOrders')
            .doc(widget.orderID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          if (!snapshot.hasData)
            return new Text("There's problem loading this page.",
                style: TextStyle(color: Color(0xffcccccc)));
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
//                      return a loading screen of sorts
            case ConnectionState.waiting:
              return new SpinKitChasingDots(
                color: Color(0xffff8181),
                size: 50.0,
                duration: Duration(milliseconds: 2000),
              );
            default:
              var orderDetails = snapshot.data;
              return new Scaffold(
                backgroundColor: Color(0xff202020),
                appBar: AppBar(
                  centerTitle: true,
                  // Here we take the value from the MyHomePage object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text('Order Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: Color(0xff202020),
                  elevation: 0.0,
                ),
                body: Container(
                  padding: EdgeInsets.only(left: 18, right: 18),
                  child: ListView(
                    children: <Widget>[
                      SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(widget.orderID,
                              style: TextStyle(
                                  fontSize: 24,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                          FlatButton(
                            color: Color(0xfffff4f2),
                            onPressed: () {
                              showAlertDialog(context, orderDetails["phone"]);
                            },
                            child: Container(
                              width: width,
                              child: Center(
                                child: Text('contact',
                                    style: TextStyle(color: Color(0xff202020))),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Name:',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                          Text(orderDetails.data()["name"],
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Phone:',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                          Text(orderDetails.data()["phone"],
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Date:',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                          Text(
                              getdate(orderDetails.data()['timestamp'], 'date'),
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Time:',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                          Text(
                              getdate(orderDetails.data()['timestamp'], 'time'),
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Ordered Items',
                              style: TextStyle(
                                  fontSize: 23,
                                  color: Color(0xffcccccc),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 15),
                      // text widget goes here
                      BurgerOrderDetails(
                        burgerName: 'Item',
                        burgerPrice: "Price",
                        burgerQuantity: "Qty",
                      ),
                      SizedBox(height: 5),
                      Container(
                          height: 1,
                          color: Color(0xffcccccc),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                          )),
                      SizedBox(height: 5),
                      load(orderDetails.data()["items"], widget.orderID),
                      SizedBox(height: 5),
                      Container(
                          height: 1,
                          color: Color(0xffcccccc),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                          )),
                      SizedBox(height: 5),
                      gettotal(orderDetails.data()["items"])
                    ],
                  ),
                ),
                floatingActionButton: orderDetails.data()["completed"] == '1'
                    ? FloatingActionButton.extended(
                        onPressed: () {
                          // Add your onPressed code here!
                          //complete_order(widget.orderID);
                          print("you can't uncomplete an order");
                        },
                        label: Padding(
                          padding: const EdgeInsets.only(
                              top: 18.0, bottom: 18.0, right: 18),
                          child: Text('Completed',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 17)),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(
                              top: 18.0, bottom: 18.0, left: 18),
                          child: Icon(
                            Icons.done_all,
                            color: Colors.black,
                            size: 18.0,
                            semanticLabel: 'Marked Order as Complete',
                          ),
                        ),
                        backgroundColor: Color(0xffcccccc),
                      )
                    : FloatingActionButton.extended(
                        onPressed: () {
                          // Add your onPressed code here!
                          complete_order(
                              widget.orderID, orderDetails["complete"]);
                        },
                        label: Padding(
                          padding: const EdgeInsets.only(
                              top: 18.0, bottom: 18.0, right: 18),
                          child: Text('Complete',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 17)),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(
                              top: 18.0, bottom: 18.0, left: 18),
                          child: Icon(
                            Icons.done_all,
                            color: Colors.black,
                            size: 18.0,
                            semanticLabel: 'Mark Order as Complete',
                          ),
                        ),
                        backgroundColor: Color(0xffff8181),
                      ),
              );
          }
        });
  }
}

Widget load(orderDetails, orderId) {
  // print(orderDetails[i]);
  List<Widget> list = new List<Widget>();
  for (var i = 0; i < orderDetails.length; i++) {
    final data = json.decode(orderDetails[i]) as Map;
    // final data = myMap as Map;

    final burgerName = data['burgername'];
    final burgerQty = data['quantity'];
    final burgerprice = data['newPrice'].toString();
    // print('$name,$value');
    list.add(BurgerOrderDetails(
        orderId: orderId,
        burgerName: burgerName,
        burgerPrice: burgerprice,
        burgerQuantity: burgerQty));
  }
  return Column(children: list);
}

Widget loadcustomBurger(orderDetails) {
  List<Widget> list = new List<Widget>();

//       print(testArray(myburgerOrder,myburgerOrder[i]));
  final myburgerOrder = json.decode(orderDetails) as Map;
  myburgerOrder.forEach((k, v) => list.add(Container(
        margin: EdgeInsets.only(bottom: 10, top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('${k}:',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xffcccccc),
                )),
            Text('${testArray(myburgerOrder, k)}',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xffcccccc),
                ))
          ],
        ),
      )));

  return Column(children: list);
}

String testArray(listName, arrName) {
  String items = '';
  for (int i = 0; i < listName[arrName].length; i++) {
//       this is the items in the category custom burger
//      to put commas after every item that is not either the last item
//       or ther only item in the array
    items += listName[arrName].length > 1
        ? listName[arrName][i] ==
                listName[arrName][listName[arrName].length - 1]
            ? listName[arrName][i]
            : listName[arrName][i] + ','
        : listName[arrName][i];
  }

  return items.toString();
}

Widget gettotal(orderDetails) {
  // print(orderDetails[i]);
  int total = 0;
  int qty = 0;
  for (var i = 0; i < orderDetails.length; i++) {
    final data = json.decode(orderDetails[i]) as Map;
    // final data = myMap as Map;

    final burgerprice = data['newPrice'];
    total += int.parse(burgerprice);

    final burgerQty = data['quantity'];
    qty += int.parse(burgerQty);
    // print('$name,$value');

  }
  return Container(
    child: BurgerOrderDetails(
      burgerName: 'Order Total',
      burgerPrice: total.toString(),
      burgerQuantity: qty.toString(),
    ),
  );
}

String getQty(orderDetails) {
  // print(orderDetails[i]);

  int qty = 0;
  for (var i = 0; i < orderDetails.length; i++) {
    final data = json.decode(orderDetails[i]) as Map;
    // final data = myMap as Map;

    final burgerQty = data['quantity'];
    qty += int.parse(burgerQty);
    // print('$name,$value');

  }
  return qty.toString();
}

String thousands(inte) {
  var f = new NumberFormat("#,###", "en_US");
  return f.format(inte).toString();
}

class BurgerOrderDetails extends StatelessWidget {
  const BurgerOrderDetails({
    Key key,
    this.burgerName,
    this.burgerPrice,
    this.burgerQuantity,
    this.orderId,
  }) : super(key: key);
  final String burgerName, burgerPrice, burgerQuantity, orderId;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.5;
    double hfwidth = MediaQuery.of(context).size.width * 0.2;
    return burgerName == "Custom Burger"
        ? GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CustomBurger(
                            orderId: orderId,
                          )));
            },
            child: Container(
                // this is a custom burger
                // change the background to a lighter shade and when clicked open the next page
                padding: EdgeInsets.only(top: 15, bottom: 15),
                color: Color(0x22ff8181),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                        width: width,
                        child: Text(burgerName,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xffcccccc),
                            ))),
                    Container(
                        width: hfwidth,
                        child: Center(
                            child: Text(burgerPrice,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                )))),
                    Container(
                        width: hfwidth,
                        child: Center(
                            child: Text(burgerQuantity,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xffcccccc),
                                )))),
                  ],
                )),
          )
        : Container(
            margin: EdgeInsets.only(top: 15, bottom: 15),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                    width: width,
                    child: Text(burgerName,
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xffcccccc),
                        ))),
                Container(
                    width: hfwidth,
                    child: Center(
                        child: Text(burgerPrice,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xffcccccc),
                            )))),
                Container(
                    width: hfwidth,
                    child: Center(
                        child: Text(burgerQuantity,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xffcccccc),
                            )))),
              ],
            ));
  }
}

complete_order(orderNumber, val) {
  FirebaseFirestore.instance
      .doc('burgerOrders/$orderNumber')
      .update({"completed": "1"}).then((result) {
    // print(val);
  }).catchError((onError) {
    print("Error occured $onError");
  });
}

String getdate(ts, date) {
  String myresult;
  if (date == 'date') {
    myresult = DateFormat.yMMMd().format(ts.toDate());
  } else if (date == 'time') {
    myresult = DateFormat.jm().format(ts.toDate());
  }
  return myresult.toString();
}

String oneWeekAgo() {
  DateTime today = new DateTime.now();
  DateTime sevenDaysAgo = today.subtract(new Duration(days: 7));

  String formattedDate = DateFormat('yyyy/MM/dd').format(sevenDaysAgo);

  return formattedDate;
}

String oneMonthAgo() {
  DateTime today = new DateTime.now();
  DateTime oneMonthAgo = today.subtract(new Duration(days: 30));

  String formattedDate = DateFormat('yyyy/MM/dd').format(oneMonthAgo);

  return formattedDate;
}

String datetoday() {
  DateTime today = new DateTime.now();

  String formattedDate = DateFormat('yyyy/MM/dd').format(today);

  return formattedDate;
}

class Stats extends StatefulWidget {
  @override
  _StatsState createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  int lifetimeTotalOrders = 0;
  int weeklyTotalOrders = 0;
  int todayTotalOrders = 0;
  int monthlyTotalOrder = 0;
  int lifetimeTotalMoney = 0;
  int weeklyTotalMoney = 0;
  int todayTotalMoney = 0;
  int monthlyTotalMoney = 0;
  @override
  initState() {
    super.initState();
    queryLifetimeOrders();
    queryOrdersTodayTotal();
    queryOrdersThisMonthTotal();
    queryOrdersThisWeekTotal();
    queryLifetimeMoney();
    queryMoneyTodayTotal();
    queryMoneyThisMonthTotal();
    queryMoneyThisWeekTotal();
  }

  int getTotalBurgerMoney(orderDetails) {
    // print(orderDetails[i]);
    int totalm = 0;
    int qty = 0;
    for (var i = 0; i < orderDetails.length; i++) {
      final data = json.decode(orderDetails[i]) as Map;
      // final data = myMap as Map;

      final burgerprice = data['newPrice'];
      totalm += int.parse(burgerprice);

      // print('$name,$value');
    }
    return totalm;
  }

  int getTotalBurgerQty(orderDetails) {
    int qty = 0;
    for (var i = 0; i < orderDetails.length; i++) {
      final data = json.decode(orderDetails[i]) as Map;
      // final data = myMap as Map;

      final burgerQty = data['quantity'];
      qty += int.parse(burgerQty);
      // print('$name,$value');

    }
    return qty;
  }

  void queryLifetimeMoney() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs.fold(
          0, (tot, doc) => tot + getTotalBurgerMoney(doc.data()['items']));

      setState(() {
        lifetimeTotalMoney = tempTotal;
      });
    });
  }

  void queryMoneyTodayTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isEqualTo: datetoday())
        // order must be complete to
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs.fold(
          0, (tot, doc) => tot + getTotalBurgerMoney(doc.data()['items']));

      setState(() {
        todayTotalMoney = tempTotal;
      });
    });
  }

  void queryMoneyThisWeekTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        // order must be complete to
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs.fold(
          0, (tot, doc) => tot + getTotalBurgerMoney(doc.data()['items']));

      setState(() {
        weeklyTotalMoney = tempTotal;
      });
    });
  }

  void queryMoneyThisMonthTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs.fold(
          0, (tot, doc) => tot + getTotalBurgerMoney(doc.data()['items']));

      setState(() {
        monthlyTotalMoney = tempTotal;
      });
    });
  }

  void queryLifetimeOrders() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs
          .fold(0, (tot, doc) => tot + getTotalBurgerQty(doc.data()['items']));

      setState(() {
        lifetimeTotalOrders = tempTotal;
      });
    });
  }

  void queryOrdersTodayTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isEqualTo: datetoday())
        // order must be complete to
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs
          .fold(0, (tot, doc) => tot + getTotalBurgerQty(doc.data()['items']));

      setState(() {
        todayTotalOrders = tempTotal;
      });
    });
  }

  void queryOrdersThisWeekTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        // order must be complete to
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs
          .fold(0, (tot, doc) => tot + getTotalBurgerQty(doc.data()['items']));

      setState(() {
        weeklyTotalOrders = tempTotal;
      });
    });
  }

  void queryOrdersThisMonthTotal() {
    FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .where("completed", isEqualTo: "1")
        .snapshots()
        .listen((snapshot) {
      int tempTotal = snapshot.docs
          .fold(0, (tot, doc) => tot + getTotalBurgerQty(doc.data()['items']));

      setState(() {
        monthlyTotalOrder = tempTotal;
      });
    });
  }

  Future<String> totalOrderCount() async {
    QuerySnapshot _myDoc =
        await FirebaseFirestore.instance.collection('burgerOrders').get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrderCompletedCount() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where("completed", isEqualTo: "1")
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrderCountToday() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where("date", isEqualTo: "2020/08/09")
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrderCompletedToday() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where("date", isEqualTo: datetoday())
        .where("completed", isEqualTo: "1")
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrderCountThisWeek() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrdersCompletedThisWeek() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneWeekAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .where("completed", isEqualTo: "1")
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrderCountThisMonth() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneMonthAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  Future<String> totalOrdersCompletedThisMonth() async {
    QuerySnapshot _myDoc = await FirebaseFirestore.instance
        .collection('burgerOrders')
        .where('date', isGreaterThanOrEqualTo: oneMonthAgo())
        .where('date', isLessThanOrEqualTo: datetoday())
        .where("completed", isEqualTo: "1")
        .get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    return _myDocCount.length.toString(); // Count of Documents in Collection
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Lifetime Stats',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Total Burgers sold',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text('$lifetimeTotalOrders',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Total Orders received',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCount(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Total Orders completed',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCompletedCount(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Total Money Earned',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text(thousands(lifetimeTotalMoney),
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Today',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Burgers sold ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text('$todayTotalOrders',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders received',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCountToday(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders completed',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCompletedToday(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Money Earned ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text(thousands(todayTotalMoney),
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('This Week',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Burgers sold ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text('$weeklyTotalOrders',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders received',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCountThisWeek(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders completed',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrdersCompletedThisWeek(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Money Earned ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text(thousands(weeklyTotalMoney),
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('This Month',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Burgers sold ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text('$monthlyTotalOrder',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders received',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrderCountThisMonth(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('orders completed',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              FutureBuilder<String>(
                  future: totalOrdersCompletedThisMonth(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    if (!snapshot.hasData)
                      return new Text("0",
                          style: TextStyle(color: Colors.blue));
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        //                      return a loading screen of sorts
                        return new SpinKitChasingDots(
                          color: Color(0xffff8181),
                          size: 20.0,
                          duration: Duration(milliseconds: 2000),
                        );
                      default:
                        return Text('${snapshot.data}',
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Color(0xffcccccc)));
                    }
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Money Earned ',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
              Text(thousands(monthlyTotalMoney),
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: Color(0xffcccccc))),
            ],
          ),
        ],
      )),
    );
  }
}

// custom burger page
// post a message to the website
// post a recipe(website for this)
class CustomBurger extends StatefulWidget {
  final String orderId;
  const CustomBurger({Key key, this.orderId}) : super(key: key);
  @override
  _CustomBurgerState createState() => _CustomBurgerState();
}

class _CustomBurgerState extends State<CustomBurger> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.3;

    // print(orderDetails[i]);
    return Scaffold(
      backgroundColor: Color(0xff202020),
      appBar: AppBar(
        centerTitle: true,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Custom Burger Details',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xff202020),
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('customBurgerOrders')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError)
              return Center(
                  child: Text(
                      'Error:${snapshot.error}There was an error loading this page'));
            if (!snapshot.hasData)
              return Center(child: Text('This custom Burger is empty'));
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new SpinKitChasingDots(
                  color: Color(0xffff8181),
                  size: 50.0,
                  duration: Duration(milliseconds: 2000),
                );
              default:
                return new ListView(
                  scrollDirection: Axis.vertical,
                  children: snapshot.data.docs.map((DocumentSnapshot document) {
                    if (snapshot.data.docs != null) {
                      //  create a widget that would be returned
                      Widget text;
                      if (document.id == widget.orderId) {
                        // populate the widget if it contains the custom burger we want
                        text =
                            loadcustomBurger(document.data()['orderDetails']);
                      } else {
                        text = Container(
                            child: Center(
                          child: Text('Something Went Wrong, try again later'),
                        ));
                      }
                      return text;
                    } else {
                      return new Text('empty');
                    }
                  }).toList(),
                );
            }
          },
        ),
      ),
    );
  }
}

// when app starts check for the token on the database
// if Not open the page to put in a name and save the device token
// web message

class WebMessageCard extends StatefulWidget {
  final bool activity;
  final String message;
  final String date;
  final String time;
  final String docId;
  const WebMessageCard(
      {Key key, this.activity, this.message, this.date, this.time, this.docId})
      : super(key: key);
  @override
  _WebMessageCardState createState() => _WebMessageCardState();
}

class _WebMessageCardState extends State<WebMessageCard> {
  // set state to have active and inactive based on the database
  // enable delete of message so a basic dustbin would work
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 20, bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Color(0xfffff4f2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.3),
              blurRadius: 3.0, // soften the shadow
              spreadRadius: 5.0, //extend the shadow
              offset: Offset(
                0.3, // Move to right 10  horizontally
                0.5, // Move to bottom 10 Vertically
              ),
            )
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.date, style: TextStyle(color: Colors.grey)),
                Text(widget.time, style: TextStyle(color: Colors.grey))
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(widget.message),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    delete_web_message(widget.docId);
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => CreateWebMessage()));
                  },
                  child: Icon(
                    Icons.delete,
                    color: Color(0xff202020),
                    size: 22.0,
                    semanticLabel: 'Delete Message',
                  ),
                ),
                Switch(
                  value: widget.activity,
                  onChanged: (value) {
                    setState(() {
                      isSwitched = value;

                      // update the activity of the message here
                      activity_web_message(value, widget.docId);
                    });
                  },
                  activeTrackColor: Color(0xffff8181),
                  activeColor: Color(0xffff4f4f),
                ),
                // FlatButton(
                //   child: Container(
                //       width: 50,
                //       child:
                //           Text("Delete", style: TextStyle(color: Colors.red,fontSize: 13))),
                //   onPressed: () {
                //    print('clicked');
                //   },
                // ),
              ],
            ),
          ],
        ));
  }
}

class WebMessage extends StatefulWidget {
  @override
  _WebMessageState createState() => _WebMessageState();
}

class _WebMessageState extends State<WebMessage> {
  // this will contain messages to be displayed on the website
  // add message button should be at the top
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('webMessages').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        if (!snapshot.hasData)
          return Center(
              child: new Text(
            'No Messages',
            style: TextStyle(color: Color(0xffcccccc)),
          ));

        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
//        return a loading screen of sorts
            return new SpinKitChasingDots(
              color: Color(0xffff8181),
              size: 50.0,
              duration: Duration(milliseconds: 2000),
            );
          default:
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                            "The messages created and\nactivated here would show up\nas a banner on the\nZux Burgers website.",
                            style: TextStyle(
                                fontSize: 11, fontStyle:FontStyle.italic, color: Color(0xffcccccc))),
                      ),
                      FlatButton(
                        textColor: Color(0xffcccccc),
                        color: Color(0xffff8181),
                        child: Container(
                            width: MediaQuery.of(context).size.width * 0.24,
                            child: Center(
                                child: Text("Create",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff202020),
                                    )))),
                        onPressed: () {
                          print('pressed');
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateWebMessage()));
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: new ListView(
                      scrollDirection: Axis.vertical,
                      children:
                          snapshot.data.docs.map((DocumentSnapshot document) {
                        if (snapshot.data.docs != null) {
                          return WebMessageCard(
                            activity: document.data()['activity'],
                            date: document.data()['date'],
                            time: document.data()['time'],
                            message: document.data()['message'],
                            docId: document.id,
                          );
                        } else {
                          return new Text('empty');
                        }
                      }).toList()),
                ),
              ],
            );
        }
      },
    );
  }
}

class CreateWebMessage extends StatefulWidget {
  @override
  _CreateWebMessageState createState() => _CreateWebMessageState();
}

class _CreateWebMessageState extends State<CreateWebMessage> {
  @override
  final TextEditingController webMessage = TextEditingController();

  Widget build(BuildContext context) {
    double childscrollviewheight = MediaQuery.of(context).size.height - 50;
    return Scaffold(
      backgroundColor: Color(0xff202020),
      appBar: AppBar(
        centerTitle: true,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Message',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xff202020),
        elevation: 0.0,
      ),
      body: Container(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
              // padding: const EdgeInsets.only(top:50),
              child: SizedBox(
            height: childscrollviewheight,
            child: Column(children: [
              Text(
                'This message will be shown as a banner in the Zux Burgers website',
                style: TextStyle(
                    color: Color(0xffcccccc), fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: webMessage,
                  autofocus: true,
                  cursorColor: Color(0xffff8181),
                  maxLines: 8,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xffcccccc),
                    letterSpacing: 0.7,
                  ),
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  // buildCounter: (BuildContext context, { int currentLength, int maxLength, bool isFocused }) => null,
                  decoration: InputDecoration.collapsed(
                    hintText: "Type Message...",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xffcccccc),
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FlatButton(
                      textColor: Color(0xffcccccc),
                      color: Color(0xffff8181),
                      child: Container(
                          width: 50,
                          child: Center(
                              child: Text("Submit",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff202020),
                                  )))),
                      onPressed: () {
                        String message = webMessage.text;
                        message != ''
                            // ignore: unnecessary_statements
                            ? addMessage(message, context)
                            : Fluttertoast.showToast(
                                msg: "The Message can't be empty",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Color(0xffff8181),
                                textColor: Color(0xff202020),
                                fontSize: 13.0);
                      },
                    ),
                  ])
            ]),
          ))),
    );
  }
}

addMessage(String message, BuildContext context) {
  // Call the user's CollectionReference to add a new user
  String dateToday = DateFormat('MMM dd, y').format(DateTime.now());
  String timeNow = DateFormat.jm().format(DateTime.now());
  // String timemm = DateFormat("mm").format(DateTime.now().toUtc());
  loadingDialog(0, context);
  FirebaseFirestore.instance
      .collection('webMessages')
      .add({
        'date': dateToday,
        'message': message,
        'activity': false,
        'time': timeNow,
      })
      .then((value) => loadingDialog(1, context))
      .catchError((error) => print("Failed to add Message: $error"));
}

loadingDialog(int param, BuildContext context) {
  param == 0
      ? showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                backgroundColor: Colors.transparent,
                content: SpinKitChasingDots(
                  color: Color(0xffff8181),
                  size: 50.0,
                  duration: Duration(milliseconds: 2000),
                ));
          })
      : closeDialog(context);
}

closeDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop(context);
  Fluttertoast.showToast(
      msg: "Message Uploaded",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xff202020),
      textColor: Color(0xffcccccc),
      fontSize: 13.0);
  Navigator
      // .of(context, rootNavigator: true)
      .pop(context);
}

// function to add message to firestore
activity_web_message(bool state, String docID) {
  FirebaseFirestore.instance
      .doc('webMessages/$docID')
      .update({"activity": state}).then((result) {
    // print(val);
  }).catchError((onError) {
    print("Error occured $onError");
  });
}

delete_web_message(String docID) {
  FirebaseFirestore.instance
      .collection('webMessages')
      .doc('$docID')
      .delete()
      .then((result) {
    Fluttertoast.showToast(
        msg: "Message Deleted Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Color(0xff202020),
        textColor: Color(0xffcccccc),
        fontSize: 13.0);
  }).catchError((onError) {
    print("Error occured $onError");
  });
}

class SearchList extends StatelessWidget {
  final String orderId;
  const SearchList({
    Key key,
    this.orderId,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('burgerOrders')
          .where("orderNo", isEqualTo: orderId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        if (!snapshot.hasData)
          return Center(
              child: new Text(
            'No Orders',
            style: TextStyle(color: Color(0xffcccccc)),
          ));

        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
//        return a loading screen of sorts
            return new SpinKitChasingDots(
              color: Color(0xffff8181),
              size: 50.0,
              duration: Duration(milliseconds: 2000),
            );
          default:
            return new ListView(
              scrollDirection: Axis.vertical,
              children: snapshot.data.docs.map((DocumentSnapshot document) {
                if (snapshot.data.docs != null) {
                  return OrderCard(
                    name: document.data()['name'],
                    phoneNumber: document.data()['phone'],
                    time: DateFormat.jm()
                        .format(document.data()['timestamp'].toDate()),
                    date: DateFormat.yMMMd()
                        .format(document.data()['timestamp'].toDate()),
                    status: document.data()['completed'].toString(),
                    approval: document.data()['approved'].toString(),
                    ordernumber: document.data()['orderNo'],
                    orderItems: document.data()['items'],
                  );
                } else {
                  return new Text('empty');
                }
              }).toList(),
            );
        }
      },
    );
  }
}
