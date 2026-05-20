// user_model.dart
class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String email;
  final String primaryApiKey;
  final String? fallbackApiKey;
  final bool nsfwMode;
  final String? activeModel;
  final bool isOnline;
  final String? profilePic;
  final String? yukiImpression;

  const UserModel({
    required this.id,
    required this.username,
    this.fullName,
    required this.email,
    required this.primaryApiKey,
    this.fallbackApiKey,
    required this.nsfwMode,
    this.activeModel,
    this.isOnline = false,
    this.profilePic,
    this.yukiImpression,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      email: json['email']?.toString() ?? '',
      primaryApiKey: json['primary_key']?.toString() ?? '',
      fallbackApiKey: json['fallback_key']?.toString(),
      nsfwMode: json['nsfw_mode'] == 1 || json['nsfw_mode'] == true,
      activeModel: json['model']?.toString(),
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      profilePic: json['profile_pic']?.toString(),
      yukiImpression: json['yuki_impression']?.toString(),
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? primaryApiKey,
    String? fallbackApiKey,
    bool? nsfwMode,
    String? activeModel,
    bool? isOnline,
    String? profilePic,
    String? yukiImpression,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      primaryApiKey: primaryApiKey ?? this.primaryApiKey,
      fallbackApiKey: fallbackApiKey ?? this.fallbackApiKey,
      nsfwMode: nsfwMode ?? this.nsfwMode,
      activeModel: activeModel ?? this.activeModel,
      isOnline: isOnline ?? this.isOnline,
      profilePic: profilePic ?? this.profilePic,
      yukiImpression: yukiImpression ?? this.yukiImpression,
    );
  }
}
