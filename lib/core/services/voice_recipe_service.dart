import 'package:flutter/material.dart';
import 'voice_assistant_service.dart';
import '../../data/models/food_model.dart';

class VoiceRecipeService extends ChangeNotifier {
  FoodModel? _currentFood;
  int _currentStep = -1; // -1 means introduction
  bool _isPlaying = false;
  bool _isSinhala = false;

  FoodModel? get currentFood => _currentFood;
  int get currentStep => _currentStep;
  bool get isPlaying => _isPlaying;
  bool get isSinhala => _isSinhala;

  void toggleLanguage() {
    _isSinhala = !_isSinhala;
    notifyListeners();
    if (_isPlaying) {
      repeatStep();
    }
  }

  Future<void> startCooking(FoodModel food) async {
    _currentFood = food;
    _currentStep = -1;
    _isPlaying = true;
    notifyListeners();
    
    final intro = _isSinhala 
        ? (food.voiceSummarySi ?? food.voiceSummary)
        : food.voiceSummary;
    
    await VoiceAssistantService.speak(intro);
  }

  Future<void> stopCooking() async {
    _isPlaying = false;
    _currentStep = -1;
    _currentFood = null;
    notifyListeners();
    await VoiceAssistantService.stop();
  }

  Future<void> nextStep() async {
    if (_currentFood == null) return;
    
    final steps = _isSinhala 
        ? (_currentFood!.recipeStepsSi ?? _currentFood!.recipeSteps)
        : _currentFood!.recipeSteps;

    if (_currentStep < steps.length - 1) {
      _currentStep++;
      _isPlaying = true;
      notifyListeners();
      await VoiceAssistantService.speak("Step ${_currentStep + 1}: ${steps[_currentStep]}");
    } else {
      await VoiceAssistantService.speak(_isSinhala ? "ඔබේ ආහාරය දැන් සූදානම්. භුක්ති විඳින්න!" : "Your dish is ready. Enjoy your meal!");
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> previousStep() async {
    if (_currentFood == null || _currentStep <= 0) return;
    
    _currentStep--;
    notifyListeners();
    await repeatStep();
  }

  Future<void> repeatStep() async {
    if (_currentFood == null) return;
    
    if (_currentStep == -1) {
      final intro = _isSinhala 
          ? (_currentFood!.voiceSummarySi ?? _currentFood!.voiceSummary)
          : _currentFood!.voiceSummary;
      await VoiceAssistantService.speak(intro);
      return;
    }

    final steps = _isSinhala 
        ? (_currentFood!.recipeStepsSi ?? _currentFood!.recipeSteps)
        : _currentFood!.recipeSteps;

    await VoiceAssistantService.speak("Step ${_currentStep + 1}: ${steps[_currentStep]}");
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await VoiceAssistantService.stop();
      _isPlaying = false;
    } else {
      _isPlaying = true;
      await repeatStep();
    }
    notifyListeners();
  }
}
