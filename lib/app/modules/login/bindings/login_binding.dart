import 'package:get/get.dart';
import 'package:google_login/app/modules/login/controllers/login_controller.dart';
import 'package:google_login/app/modules/services/auth_services.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AuthService as permanent (won't be disposed)
    Get.put<AuthService>(AuthService(), permanent: true);
    
    // Initialize AuthController
    Get.lazyPut<LoginController>(() => LoginController());
  }
}