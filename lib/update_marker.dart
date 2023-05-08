
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
   HomePage({ Key? key, this.title}) : super(key: key);

  String? title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final LatLng center = const LatLng(-33.86711, 151.1947171);
  GoogleMapController? controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  PageController _pageController = PageController(viewportFraction: 0.9);
  MarkerId? previousMarker;

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  @override
  void initState() {
    super.initState();

    _addMarkers();

    _pageController.addListener(() {
      int page = _pageController.page!.toInt();
      _highlightMaker(MarkerId("markerId$page"));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _highlightMaker(MarkerId markerId) {
    // select marker by id
    final Marker marker = markers[markerId]!;

    if (marker != null) {
      setState(() {
        if (previousMarker != null) {
          final Marker resetOld = markers[previousMarker]
              !.copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markers[previousMarker!] = resetOld;
        }

        // update the selected marker by changing the icon using copyWith() helper method
        final Marker newMarker = marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );

        markers[markerId] = newMarker;
        previousMarker = newMarker.markerId;

        // zoom in to the selected camera position
        controller?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            bearing: 0,
            target: newMarker.position,
            zoom: 12.0,
          ),
        ));
      });
    }
  }

  void _addMarkers() {
    for (int i = 0; i < 12; i++) {
      String id = 'markerId$i';
      final MarkerId markerId = MarkerId(id);
      final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(
          center.latitude + sin(i * pi / 6.0) / 20.0,
          center.longitude + cos(i * pi / 6.0) / 20.0,
        ),
        infoWindow: InfoWindow(title: id),
        onTap: () {
          _pageController.jumpToPage(i);
        },
      );
      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  Widget _pageViewBuilder(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3.8 / 2.5,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (BuildContext context, int itemIndex) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage('https://placeimg.com/640/480/any')),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Colors.redAccent,
            ),
          );
        },
        itemCount: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          flex: 7,
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-33.852, 151.211),
              zoom: 11.0,
            ),
            markers: Set<Marker>.of(markers.values),
          ),
        ),
        _pageViewBuilder(context),
      ]),
    );
  }
}