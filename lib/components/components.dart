import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Position? cl;
var lat;
var long;
StreamSubscription<Position>? positionStream;
GoogleMapController? gmc;

// Start Polyline
Map<PolylineId, Polyline> polylines = {};
Map<dynamic, double> distances = {};

List<LatLng> polylineCoordinates = [];
PolylinePoints polylinePoints = PolylinePoints();
String googleAPiKey = "AIzaSyDtdWNgEPfUGq9OYBJtO5EzNcP000t9Oao";

final Completer<GoogleMapController> controllerMap = Completer();
final TextEditingController editHeight = TextEditingController();
final TextEditingController editRadius = TextEditingController();
final GlobalKey<FormState> fKey = GlobalKey();

var currlat = 30.415010;
var currlong = 31.565889;

double distance = 0.0;
double totalDistance = 0.0;

var state1 = false;
var state2 = false;
var state3 = false;

var basket_1_lat_doub;
var basket_1_lon_doub;
var basket_1_lat;
var basket_1_long;

var new_id = 1;

var searchController = TextEditingController();
CameraPosition? kGooglePlex;
var basket = FirebaseFirestore.instance.collection('baskets');
Set<Marker> myMarker = {};
Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

var de, m;
var databaseref = FirebaseDatabase.instance.ref().child("esp");

Future<Marker> positionMarker(id, pLatt, pLonn, st, distance) async {
  pLatt = basket_1_lat;
  pLonn = basket_1_long;
  return Marker(
    markerId: MarkerId(id.toString()),
    infoWindow: InfoWindow(
      title: "Total Distance: ${distance.toStringAsFixed(
        2,
      )} KM",
      snippet: 'h = 26 CM,r = 11 CM,Volume = 9,878.44 CM^2',
    ),
    position: LatLng(pLatt, pLonn), //30.415010, 31.565889
    icon: (st == 0)
        ? await BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/images/Empty.png")
        : (st == 1)
            ? await BitmapDescriptor.fromAssetImage(
                ImageConfiguration.empty, "assets/images/middle.png")
            : await BitmapDescriptor.fromAssetImage(
                ImageConfiguration.empty, "assets/images/Full.png"),
  );
}

Future<void> changeBasketIconState() async {
  print(de);
  if (de == 0) {
    myMarker.add(
      await positionMarker(
          new_id.toString(), basket_1_lat, basket_1_long, de, distance),
    );
  } else if (de == 1) {
    myMarker.add(
      await positionMarker(
          new_id.toString(), basket_1_lat, basket_1_long, de, distance),
    );
  } else if (de == 2) {
    myMarker.add(
      await positionMarker(
          new_id.toString(), basket_1_lat, basket_1_long, de, distance),
    );
  }
}

double? TextToDouble(String s) {
  var list = s.split("");
  print(list);
  var new_list = [];

  for (int i = 0; i < list.length; i++) {
    if (list[i] == '"') {
      for (int j = i + 1; j < list.length; j++) {
        if (list[j] == '"') {
          break;
        }
        new_list.add(list[j]);
      }
      if (new_list.length > 0) {
        print(new_list);
        var y = new_list.join();

        var num = double.parse(y);
        print(basket_1_lat_doub);
        return num;
      }
    }
  }
}

Widget queryBasketsInfo() {
  return StreamBuilder(
    stream: basket.snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.hasData) {
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            basket_1_lat = snapshot.data!.docs[index]['lat'];
            basket_1_long = snapshot.data!.docs[index]['lon'];
            return Column(
              children: [
                Container(
                  margin: const EdgeInsetsDirectional.only(top: 500, end: 0),
                  child: Card(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Text('Latitude : $basket_1_lat',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        return Container();
      }
    },
  );
}

setMarkerCustomImage() async {
  myMarker.add(
    Marker(
      markerId: MarkerId("3"),
      infoWindow: InfoWindow(
        title: "Mit Ghamr",
      ),
      position: LatLng(30.713261, 31.259550),
      icon: await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/images/Full.png"),
      // onTap: (){
      //   displayDistance2();
      // },
    ),
  );

  myMarker.add(
    Marker(
      markerId: MarkerId("4"),
      infoWindow: InfoWindow(
        title: "Mansoura",
      ),
      position: LatLng(31.040949, 31.378469),
      icon: await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/images/middle.png"),
      // onTap: (){
      //   displayDistance2();
      // },
    ),
  );
}

FirebaseAnimatedList retSensor() {
  return FirebaseAnimatedList(
    query: databaseref,
    itemBuilder: (BuildContext context, DataSnapshot snap,
        Animation<double> animation, int index) {
      de = snap.child('int').value;
      // if (de == 0) {
      //   m = "Emp";
      // } else if (de == 1) {
      //   m = "Full";
      // }
      m = de;
      return Column(
        children: [
          Container(
            margin: EdgeInsetsDirectional.only(top: 400, end: 230),
            child: Card(
              child: Container(
                padding: EdgeInsets.all(10),
                child: Text('Sensor : $m',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );
    },
  );
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}
