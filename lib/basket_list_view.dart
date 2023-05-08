import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'components/components.dart';

class BasketListView extends StatefulWidget {
  const BasketListView({Key? key}) : super(key: key);

  @override
  State<BasketListView> createState() => _BasketListViewState();
}

class _BasketListViewState extends State<BasketListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baskets'),
      ),
      body: basketListViewState(),
    );
  }

  var basket = FirebaseFirestore.instance.collection('baskets');

  Widget basketListViewState() {
    return StreamBuilder(
      stream: basket.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Row(
                          children: [
                            const Spacer(),
                            const Text(
                              'ID',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              snapshot.data!.docs[index]['Id'].toString(),
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
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'HEIGHT',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 35.0,
                            width: 110.0,
                            child: TextField(
                              controller: editHeight,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(8),
                                hintText: snapshot.data!.docs[index]['height']
                                    .toString(),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {},
                              onTap: () {},
                              onSubmitted: (value) {
                                basket
                                    .doc(snapshot.data!.docs[index].id
                                        .toString())
                                    .update({
                                  'height': editHeight.text,
                                });
                              },
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'LATITUDE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            snapshot.data!.docs[index]['lat'].toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              var id =
                                  snapshot.data!.docs[index]['Id'].toString();
                              cl = await Geolocator.getCurrentPosition()
                                  .then((value) => value);
                              var lat = cl!.latitude;
                              var long = cl!.longitude;
                              basket_1_lat = lat;
                              basket_1_long = long;
                              var newPosition = LatLng(lat, long);
                              gmc?.animateCamera(
                                  CameraUpdate.newLatLngZoom(newPosition, 15));
                              polylineCoordinates.clear();
                              basket
                                  .doc(snapshot.data!.docs[index].id.toString())
                                  .update({
                                'lat': basket_1_lat,
                                'lon': basket_1_long,
                              });
                              polylineCoordinates.clear();
                            },
                            icon: const Icon(
                              Icons.edit,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'LONGITUDE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            snapshot.data!.docs[index]['lon'].toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'RADIUS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 35,
                            width: 110,
                            child: TextField(
                              controller: editRadius,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(8),
                                hintText: snapshot.data!.docs[index]['radius']
                                    .toString(),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {},
                              onTap: () {},
                              onSubmitted: (value) {
                                basket
                                    .doc(snapshot.data!.docs[index].id
                                        .toString())
                                    .update({
                                  'radius': editRadius.text,
                                });
                              },
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Row(
                          children: [
                            const Spacer(),
                            if (de == 0) Image.asset('assets/images/Empty.png'),
                            if (de == 1)
                              Image.asset('assets/images/middle.png'),
                            if (de == 2) Image.asset('assets/images/Full.png'),
                            const Spacer(),
                            IconButton(
                              onPressed: () async {
                                markers.clear();
                                polylineCoordinates.clear();
                                basket
                                    .doc(snapshot.data!.docs[index].id
                                        .toString())
                                    .delete();
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  void initState() {
    basketListViewState();
    super.initState();
  }
}
