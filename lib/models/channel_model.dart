class ChannelModel {
  ChannelModel({
    required this.companyName,
    required this.country,
    required this.address,
    required this.city,
    required this.staffAutoLogOff,
    required this.noOfDecimalPlaces,
    required this.channelId,
    required this.channelName,
  });
  final String companyName;
  final int channelId;
  final String channelName;
  final String country;
  final String address;
  final String city;
  final bool staffAutoLogOff;
  final int noOfDecimalPlaces;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      companyName: json['companyName'] ?? '',
      country: json['country'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      staffAutoLogOff: json['staffAutoLogOff'],
      noOfDecimalPlaces: json['noOfDecimalPlaces'],
      channelId: json['channelId'],
      channelName: json['name'],
    );
  }
}
