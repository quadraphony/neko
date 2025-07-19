import 'package:flutter/foundation.dart';

class VpnGroup {
  final String id;
  final String name;
  final String? subscriptionUrl;

  VpnGroup({
    required this.id,
    required this.name,
    this.subscriptionUrl,
  });

  factory VpnGroup.fromJson(Map<String, dynamic> json) {
    return VpnGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      subscriptionUrl: json['subscriptionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subscriptionUrl': subscriptionUrl,
    };
  }

  VpnGroup copyWith({
    String? id,
    String? name,
    ValueNotifier<String?>? subscriptionUrl,
  }) {
    return VpnGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      subscriptionUrl: subscriptionUrl != null ? subscriptionUrl.value : this.subscriptionUrl,
    );
  }
}


