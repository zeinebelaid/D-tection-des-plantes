
class Plant {
  int plantId;
  String size;
  double? rating;

  String category;
  String plantName;
  String imageURL;

  // Constructor for Plant
  Plant({
    required this.plantId,
    required this.category,
    required this.plantName,
    required this.size,
    required this.rating,
    required this.imageURL,

    // Convert the Plant object into a Map to store in Firestore
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      plantId: map['plantId'],
      size: map['size'],
      rating: (map['rating'] != null) ? map['rating'].toDouble() : null,
      category: map['category'],
      plantName: map['plantName'],
      imageURL: map['imageURL'],
    );
  }
}
