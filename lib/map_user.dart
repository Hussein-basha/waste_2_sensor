import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'components/components.dart';

class MapUserWasteManagementSystem extends StatefulWidget {
  const MapUserWasteManagementSystem({Key? key}) : super(key: key);

  @override
  State<MapUserWasteManagementSystem> createState() =>
      _MapUserWasteManagementSystem();
}

class _MapUserWasteManagementSystem
    extends State<MapUserWasteManagementSystem> {
  @override
  void initState() {
    getPermission();
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      changeMaker(position.latitude, position.longitude);
      getLatAndLongWorker();
      getMarkerData();
      getPolyline(position.latitude, position.longitude);
    });

    super.initState();
  }

  final Completer<GoogleMapController> _controllerMap = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User',
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    kGooglePlex == null
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: 550.0,
                            width: 400.0,
                            child: GoogleMap(
                              markers: Set<Marker>.of(markers.values),
                              polylines: Set<Polyline>.of(polylines.values),
                              myLocationEnabled: true,
                              tiltGesturesEnabled: true,
                              compassEnabled: true,
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                              mapType: MapType.normal,
                              initialCameraPosition: kGooglePlex!,
                              onMapCreated: (GoogleMapController controller) {
                                _controllerMap.complete(controller);
                              },
                            ),
                          ),
                  ],
                ),
              ],
            ),
            Row(
              children: const [
                ImageIcon(
                  AssetImage("assets/images/Empty.png"),
                  color: Colors.green,
                ),
                SizedBox(
                  width: 6,
                ),
                Text("Basket -> EMPTY "),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: const [
                ImageIcon(
                  AssetImage("assets/images/Full.png"),
                  color: Colors.red,
                ),
                SizedBox(
                  width: 6,
                ),
                Text("Basket -> FULL "),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: const [
                ImageIcon(
                  AssetImage("assets/images/middle.png"),
                  color: Colors.yellow,
                ),
                SizedBox(
                  width: 6,
                ),
                Text("Basket -> MIDDLE(NOT FULL) "),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
          )).show();
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
    const markerId = MarkerId("worker");
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

  void initMarker(specify, specifyId) async {
    var markerIdVal = specifyId;
    final MarkerId markerId = MarkerId(markerIdVal);
    final marker = Marker(
      markerId: markerId,
      position: LatLng(specify['lat'], specify['lon']),
      onTap: () {
        showModalBottomSheet(
            constraints: const BoxConstraints(maxHeight: 270),
            backgroundColor: Colors.black45,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                topLeft: Radius.circular(15),
              ),
            ),
            context: context,
            builder: (builder) {
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
                        Text(
                          specify['height'].toString(),
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
                        Text(
                          specify['radius'].toString(),
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
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (de == 0) Image.asset('assets/images/Empty.png'),
                          if (de == 1) Image.asset('assets/images/middle.png'),
                          if (de == 2) Image.asset('assets/images/Full.png'),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
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
}

// AIzaSyDtdWNgEPfUGq9OYBJtO5EzNcP000t9Oao
