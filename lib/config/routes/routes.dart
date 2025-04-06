import 'package:flutter/material.dart';
import '../../features/splashScreen/view/splash_screen.dart';


class AppRoutes {
  static const landingPage = "/landingPage";
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case landingPage:
        return _materialRoute( SplashScreen());
      default:
        return _materialRoute( SplashScreen());
    }
  }
  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}



class VerifyAccountData {
  final String verifyToken;
  final String firstName;
  final String lastName;

  VerifyAccountData({
    required this.verifyToken,
    this.firstName = '',
    this.lastName = '',
  });
}

class EditProfileArgModel {
  final String name;
  final String phoneNumber;
  final bool isPrivate;

  EditProfileArgModel({
    required this.name,
    required this.phoneNumber,
    required  this.isPrivate,
  });
}


