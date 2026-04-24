import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isDisposed = false;

  AuthProvider();

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => false;

  Future<void> init() async {
    _isLoading = true;
    _notify();
    _isLoading = false;
    _notify();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}