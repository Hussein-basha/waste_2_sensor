import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'basket_list_view.dart';
import 'components/components.dart';
import 'constants.dart';
import 'map_user.dart';

class MapWorkerWasteManagementSystem extends StatefulWidget {
  const MapWorkerWasteManagementSystem({Key? key}) : super(key: key);

  @override
  State<MapWorkerWasteManagementSystem> createState() =>
      _MapWorkerWasteManagementSystem();
}

class _MapWorkerWasteManagementSystem
    extends State<MapWorkerWasteManagementSystem> {
  @override
  void initState() {
    getPermission();
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      changeMaker(position.latitude, position.longitude);
      getMarkerData();
      getPolyline(position.latitude, position.longitude);
    });
    getLatAndLongWorker();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Worker',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Baskets"),
                    titlePadding: EdgeInsets.all(20),
                    // content: displayNotification(),
                    contentPadding: EdgeInsets.all(20),
                    contentTextStyle: TextStyle(
                      color: Colors.green,
                    ),
                    titleTextStyle: TextStyle(
                      color: Colors.deepPurple,
                    ),
                    backgroundColor: Colors.grey[300],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.notifications_active,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const BasketListView();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const MapUserWasteManagementSystem();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.verified_user_outlined,
            ),
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          retSensor(),
          queryBasketsInfo(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: defaultFormField(
                  controller: searchController,
                  type: TextInputType.text,
                  onChange: (value) {},
                  onSubmit: (value) async {},
                  onTap: () {},
                  label: 'Location',
                  hint: 'Move Basket To New Location',
                  validate: (String value) {
                    if (value.isEmpty) {
                      return 'Location Must Not Be Empty';
                    }
                    return null;
                  },
                  prefix: Icons.location_on,
                ),
              ),
              kGooglePlex == null
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: SizedBox(
                        height: 600.0,
                        width: 400.0,
                        child: GoogleMap(
                          markers: Set<Marker>.of(markers.values),
                          polylines: Set<Polyline>.of(polylines.values),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          tiltGesturesEnabled: true,
                          compassEnabled: true,
                          trafficEnabled: true,
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          mapType: MapType.normal,
                          initialCameraPosition: kGooglePlex!,
                          onMapCreated: (GoogleMapController controller) {
                            controllerMap.complete(controller);
                          },
                        ),
                      ),
                    ),
            ],
          ),
          // Positioned(
          //   top: 200,
          //   right: 0,
          //   child: Card(
          //     child: Text(' Total Distance : $distance'),
          //   ),
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await addNewBasket(new_id, distance, 0);
        },
        backgroundColor: Colors.blue.withOpacity(0.5),
        child: const Icon(
          Icons.add,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // End Polyline

  Future getPermission() async {
    bool? services;
    LocationPermission per;
    services = await Geolocator.isLocationServiceEnabled();
    if (services == false) {
      AwesomeDialog(
          context: context,
          title: "Services",
          body: const Text(
            'Services Not Enabled',
          ))
        ..show();
    }
    per = await Geolocator.checkPermission();
    if (per == LocationPermission.denied) {
      per = await Geolocator.requestPermission();
    }
    print("=============================");
    print(per);
    print("=============================");
    return per;
  }

  Future<void> getLatAndLongWorker() async {
    cl = await Geolocator.getCurrentPosition().then((value) => value);
    lat = cl!.latitude;
    long = cl!.longitude;
    kGooglePlex = CameraPosition(
      target: LatLng(lat, long),
      zoom: 9.4746,
    );

    if (mounted) setState(() {});
  }

  changeMaker(var newLat, var newLong) async {
    //myMarker.remove(Marker(markerId: MarkerId("1")));
    final markerId = MarkerId("worker");
    final marker = Marker(
      markerId: markerId,
      position: LatLng(newLat, newLong),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    // await changeBasketIconState();
    gmc?.animateCamera(CameraUpdate.newLatLng(LatLng(newLat, newLong)));
    if (mounted) {
      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  addPolyLine(specifyId) {
    PolylineId id1 = PolylineId(specifyId);
    Polyline polyline1 = Polyline(
        width: 4,
        polylineId: id1,
        color: Colors.deepPurple,
        points: polylineCoordinates);

    if (mounted) {
      setState(() {
        polylines[id1] = polyline1;
      });
    }
  }

  initPolyline(var newLat, var newLong, specify, specifyId) async {
    // Polyline From Worker To ......
    polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(newLat, newLong), // Start Polyline
        PointLatLng(specify['lat'],
            specify['lon']), //30.415010, 31.565889  // End Polyline
        travelMode: TravelMode.driving,
        wayPoints: [
          PolylineWayPoint(
            location: "From Worker To .....",
          ),
        ]);
    // if (result1.points.isNotEmpty) {
    //   result1.points.forEach((PointLatLng point) {
    polylineCoordinates.add(LatLng(newLat, newLong)); // Start Polyline
    polylineCoordinates
        .add(LatLng(specify['lat'], specify['lon'])); // End Polyline
    // }
    // );
    // }

    // calc distance
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance = calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    print(totalDistance);

    if (mounted) {
      setState(() {
        distances[specifyId] = totalDistance;
      });
    }
    var max = distances.values.first;
    distances.forEach((key, value) {
      if (value > max) {
        value = max;
        var ss = value;
        print('Min : $ss');
        addPolyLine(ss.toString());
      }
      // print('Min : $value');
    });
  }

  getPolyline(newLat, newLong) {
    if (mounted) {
      setState(() {
        FirebaseFirestore.instance.collection('baskets').get().then((value) {
          if (value.docs.isNotEmpty) {
            for (int i = 0; i < value.docs.length; i++) {
              initPolyline(newLat, newLong, value.docs[i].data(),
                  value.docs[i].id.toString());
            }
          }
        });
      });
    }
  }

  Future<void> addNewBasket(id, distance, st) async {
    cl = await Geolocator.getCurrentPosition().then((value) => value);
    lat = cl!.latitude;
    long = cl!.longitude;
    var newPosition = LatLng(lat, long);
    gmc?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));

    basket.add({
      'Id': id,
      'height': 20,
      'lat': lat,
      'lon': long,
      'radius': 14,
    }).then((DocumentReference doc) {
      print('My Document Id : ${doc.id}');
      print('Length : ${myMarker.length}');
    });

    final marker = Marker(
      markerId: MarkerId(id.toString()),
      infoWindow: InfoWindow(
        title: id,
        snippet: "Total Distance: ${distance.toStringAsFixed(
          2,
        )} KM",
      ),
      position: newPosition,
      icon: await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/images/Empty.png"),
    );

    if (mounted) {
      setState(() {
        markers[MarkerId(new_id.toString())] = marker;
      });
    }
  }

  Future<void> moveToNewLocation() async {
    cl = await Geolocator.getCurrentPosition().then((value) => value);
    lat = cl!.latitude;
    long = cl!.longitude;
    currlat = lat;
    currlong = long;
    print('curr : $currlat');
    basket_1_lat_doub = currlat;
    basket_1_lon_doub = currlong;
    print('currrrrrrrrrrrrrrrrrrrrrrr : $basket_1_lat_doub');

    var newPosition = LatLng(basket_1_lat_doub!, basket_1_lon_doub!);
    gmc?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));
    myMarker
      ..remove(myMarker.first.markerId.value)
      ..add(
        await positionMarker(
            "1", basket_1_lat_doub, basket_1_lon_doub, de, distance),
      );
    polylineCoordinates.clear();
    if (mounted) setState(() {});
  }

  void initMarker(specify, specifyId) async {
    var markerIdVal = specifyId;
    final MarkerId markerId = MarkerId(markerIdVal);
    final marker = Marker(
      markerId: markerId,
      position: LatLng(specify['lat'], specify['lon']),
      onTap: () {
        showModalBottomSheet(
            constraints: const BoxConstraints(maxHeight: 340),
            backgroundColor: Colors.black45,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                topLeft: Radius.circular(15),
              ),
            ),
            context: context,
            builder: (builder) {
              return StreamBuilder(
                stream: basket.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                const Spacer(),
                                const Text(
                                  'ID',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  specify['Id'].toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              const Text(
                                'DISTANCE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${distances[specifyId]?.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              const Text(
                                'HEIGHT',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                height: 35.0,
                                width: 110.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                  color: Colors.white,
                                ),
                                child: TextField(
                                  controller: editHeight,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                    contentPadding: const EdgeInsets.all(8),
                                    hintText: specify['height'].toString(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {},
                                  onTap: () {},
                                  onSubmitted: (value) {
                                    basket.doc(specify.id.toString()).update({
                                      'height': editHeight.text,
                                    });
                                  },
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              const Text(
                                'LATITUDE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                specify['lat'].toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                onPressed: () async {
                                  var index;
                                  // var id = specify['Id'].toString();
                                  cl = await Geolocator.getCurrentPosition()
                                      .then((value) => value);
                                  var lat = cl!.latitude;
                                  var long = cl!.longitude;
                                  basket_1_lat = lat;
                                  basket_1_long = long;
                                  var newPosition = LatLng(lat, long);
                                  gmc?.animateCamera(CameraUpdate.newLatLngZoom(
                                      newPosition, 15));
                                  polylineCoordinates.clear();
                                  basket
                                      .doc(snapshot.data!.docs[specify['Id']].id
                                          .toString())
                                      .update({
                                    'lat': basket_1_lat,
                                    'lon': basket_1_long,
                                  });
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              const Text(
                                'LONGITUDE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                specify['lon'].toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              const Text(
                                'RADIUS',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                height: 35,
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                  color: Colors.white,
                                ),
                                child: TextField(
                                  controller: editRadius,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                    contentPadding: const EdgeInsets.all(8),
                                    hintText: specify['radius'].toString(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {},
                                  onTap: () {},
                                  onSubmitted: (value) {
                                    basket.doc(specify.id.toString()).update({
                                      'radius': editRadius.text,
                                    });
                                  },
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Row(
                              children: [
                                const Spacer(),
                                if (de == 0)
                                  Image.asset('assets/images/Empty.png'),
                                if (de == 1)
                                  Image.asset('assets/images/middle.png'),
                                if (de == 2)
                                  Image.asset('assets/images/Full.png'),
                                const Spacer(),
                                IconButton(
                                  onPressed: () async {
                                    markers.clear();
                                    polylineCoordinates.clear();
                                    basket.doc(specify.id.toString()).delete();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              );
            });
      },
      // infoWindow: InfoWindow(
      //   title: ' Id : ${specify['Id']}',
      //   snippet: 'Distance : ${distances[specifyId]?.toStringAsFixed(2)} KM',
      // ),
      icon: (de == 0)
          ? await BitmapDescriptor.fromAssetImage(
              ImageConfiguration.empty, "assets/images/Empty.png")
          : (de == 1)
              ? await BitmapDescriptor.fromAssetImage(
                  ImageConfiguration.empty, "assets/images/middle.png")
              : await BitmapDescriptor.fromAssetImage(
                  ImageConfiguration.empty, "assets/images/Full.png"),
    );
    if (mounted) {
      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  // Widget ShowModalBottomSheet() {
  //   return ;
  // }

  void getMarkerData() {
    if (mounted) {
      setState(() {
        FirebaseFirestore.instance.collection('baskets').get().then((value) {
          if (value.docs.isNotEmpty) {
            new_id = 1;
            for (int i = 0; i < value.docs.length; i++) {
              initMarker(value.docs[i].data(), value.docs[i].id.toString());
              new_id++;
            }
          }
        });
      });
    }
  }

  var id_id;
  var height_height;
  var radius_radius;
  var lat_lat;
  var lon_lon;
  Widget saveData() {
    return StreamBuilder(
      stream: basket.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // MapModel model =
              //     MapModel.fromJson(snapshot.data!.docs[index].data());
              id_id = snapshot.data!.docs[index]['Id'];
              height_height = snapshot.data!.docs[index]['height'];
              radius_radius = snapshot.data!.docs[index]['radius'];
              lat_lat = snapshot.data!.docs[index]['lat'];
              lon_lon = snapshot.data!.docs[index]['lon'];
              // Map<String, dynamic> currentBasket = {
              //   'Id': id_id,
              //   'height': height_height,
              //   'radius': radius_radius,
              //   'lat': lat_lat,
              //   'lon': lon_lon,
              // };
              // basketsList.add(currentBasket);
              // for (int i = 0; i < basketsList.length; i++) {
              //   var id_print = basketsList[i]['Id'];
              //   var lat_print = basketsList[i]['lat'];
              //   var long_print = basketsList[i]['lon'];
              //   var radius_print = basketsList[i]['radius'];
              //   var height_print = basketsList[i]['height'];
              //   print(id_print);
              //   print(lat_print);
              //   print(long_print);
              //   positionMarker(id_print, lat_print, long_print, de, distance1);
              // }

              return Column(
                children: [
                  Text(id_id.toString()),
                  Text(height_height.toString()),
                  Text(radius_radius.toString()),
                  Text(lat_lat.toString()),
                  Text(lat_lat.toString()),
                ],
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  drawIconBasket() async {
    // print('Lenght           ${basketsList.length}');
    // for (int i = 0; i < basketsList.length; i++) {
    //   // print(basketsList[i]);
    //   // var id_print = basketsList[i]['Id'];
    //   // var lat_print = basketsList[i]['lat'];
    //   // var long_print = basketsList[i]['lon'];
    //   // var radius_print = basketsList[i]['radius'];
    //   // var height_print = basketsList[i]['height'];
    //   // print(id_print);
    //   // print(lat_print);
    //   // print(long_print);

    //   // var sens_r = 0;
    //   // if (id_print == '2') {
    //   //   sens_r = 1;
    //   // } else if (id_print == '3') {
    //   //   sens_r = 2;
    //   // } else if (id_print == '1') {
    //   //   sens_r = de;
    //   // }
    //   if (de == 0) {
    //     myMarker.add(
    //       await positionMarker(id_print, lat_print, long_print, de, distance1),
    //     );
    //   } else if (de == 1) {
    //     myMarker.add(
    //       await positionMarker(id_print, lat_print, long_print, de, distance1),
    //     );
    //   } else if (de == 2) {
    //     myMarker.add(
    //       await positionMarker(id_print, lat_print, long_print, de, distance1),
    //     );
    //   }
    // }

    if (mounted) {
      setState(() {});
    }
  }

  var not;
  var col;
  bool full_3 = false;
  bool full_2 = false;

  // Widget displayNotification() {
  //   if (state1 == true && state2 == true && state3 == true) {
  //     full_3 = true;
  //   } else if ((state1 == true && state2 == true) ||
  //       (state1 == true && state3 == true) ||
  //       (state2 == true && state3 == true)) {
  //     full_2 = true;
  //   }
  //   var min_distance = totalDistance1;

  //   if (totalDistance2 < min_distance) {
  //     min_distance = totalDistance2;
  //   } else if (totalDistance3 < min_distance) {
  //     min_distance = totalDistance3;
  //   }
  //   if (full_3 == true) {
  //     if (totalDistance1 == min_distance) {
  //       not = Text("Go To Basket 1");
  //     } else if (totalDistance2 == min_distance) {
  //       not = Text("Go To Basket 2");
  //     } else {
  //       not = Text("Go To Basket 3");
  //     }
  //   } else if (full_2 == true) {
  //     if (state1 == false) {
  //       if (totalDistance2 == min_distance) {
  //         not = Text("Go To Basket 2");
  //       } else {
  //         not = Text("Go To Basket 3");
  //       }
  //     } else if (state2 == false) {
  //       if (totalDistance1 == min_distance) {
  //         not = Text("Go To Basket 1");
  //       } else {
  //         not = Text("Go To Basket 3");
  //       }
  //     } else {
  //       if (totalDistance1 == min_distance) {
  //         not = Text("Go To Basket 1");
  //       } else {
  //         not = Text("Go To Basket 2");
  //       }
  //     }
  //   } else {
  //     if (state1 == true) {
  //       not = Text("Go To Basket 1");
  //     } else if (state2 == true) {
  //       not = Text("Go To Basket 2");
  //     } else if (state3 == true) {
  //       not = Text("Go To Basket 3");
  //     } else {
  //       not = Text("NO Basket FULL");
  //     }
  //     // not = Text("NO Basket FULL ");
  //   }
  //   return not;
  // }
}
// AIzaSyDtdWNgEPfUGq9OYBJtO5EzNcP000t9Oao
