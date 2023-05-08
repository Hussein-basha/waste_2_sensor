class MapModel {
  String? id;
  int? height;
  int? radius;
  double? lat;
  double? lon;

  MapModel({
    this.id,
    this.height,
    this.lat,
    this.lon,
    this.radius,
  });

  MapModel.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    radius = json['radius'];
    height = json['height'];
    lat = json['lat'];
    lon = json['lon'];
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'radius': radius,
      'height': height,
      'lat': lat,
      'lon': lon,
    };
  }
}
