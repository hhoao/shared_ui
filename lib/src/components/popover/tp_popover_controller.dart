import 'package:flutter/foundation.dart';

/// Controls visibility of a [TpPopover].
class TpPopoverController extends ChangeNotifier {
  TpPopoverController({bool isOpen = false}) : _isOpen = isOpen;

  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void show() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void hide() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() => _isOpen ? hide() : show();
}
