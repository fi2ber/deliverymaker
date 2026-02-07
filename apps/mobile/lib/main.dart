import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Get role from secure storage (after Telegram auth)
  // For now use driver role for testing maps
  const initialRole = UserRole.driver;
  
  runApp(const DeliveryApp(userRole: initialRole));
}
