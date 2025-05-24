// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  String userName;
  String userEmail;
  String photoUrl;
  String phoneNumber;

  UserModel({
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userName: json["user_name"],
    userEmail: json["user_email"],
    photoUrl: json["photo_url"],
    phoneNumber: json["phone_number"],
  );

  Map<String, dynamic> toJson() => {
    "user_name": userName,
    "user_email": userEmail,
    "photo_url": photoUrl,
    "phone_number": phoneNumber,
  };
}
