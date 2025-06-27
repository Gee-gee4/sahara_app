class ResourceModel {
  ResourceModel({
    required this.channel,
    required this.colorResource,
    required this.drawableResource,
    required this.webApiServiceUrl,
  });

  final String channel;
  final String colorResource;
  final String drawableResource;
  final String webApiServiceUrl;

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      channel: json['channel'],
      colorResource: json['colorResource'],
      drawableResource: json['drawableResource'],
      webApiServiceUrl: json['webApiServiceUrl'],
    );
  }
}
