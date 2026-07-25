import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    // Use WidgetsBinding to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loading != _isLoading) {
        _isLoading = loading;
        notifyListeners();
      }
    });
  }

  void setError(String? message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorMessage = message;
      notifyListeners();
    });
  }

  void clearError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorMessage = null;
      notifyListeners();
    });
  }
}