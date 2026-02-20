import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StorySoundManager {
  static final StorySoundManager _instance = StorySoundManager._internal();
  factory StorySoundManager() => _instance;
  StorySoundManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  bool _isMuted = false;
  
  // Play background music based on kingdom
  Future<void> playKingdomMusic(int kingdomId) async {
    if (_isMuted) return;
    
    try {
      // Note: Pour l'instant on utilise des sons système
      // Dans une vraie app, tu ajouterais des fichiers .mp3 dans assets/
      
      // Exemple de structure:
      // final musicPath = 'audio/kingdom_$kingdomId.mp3';
      // await _musicPlayer.play(AssetSource(musicPath));
      
      // Pour l'instant, on simule avec un son vide
      await _musicPlayer.setVolume(0.3);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Could not play music: $e');
    }
  }
  
  // Play sound effects
  Future<void> playSound(SoundEffect effect) async {
    if (_isMuted) return;
    
    try {
      // Dans une vraie app, tu utiliserais:
      // await _sfxPlayer.play(AssetSource(effect.path));
      
      // Pour l'instant on simule
      await _sfxPlayer.setVolume(0.5);
      print('🔊 Playing sound: ${effect.name}');
    } catch (e) {
      print('Could not play sound: $e');
    }
  }
  
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
  
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _musicPlayer.setVolume(0);
      _sfxPlayer.setVolume(0);
    } else {
      _musicPlayer.setVolume(0.3);
      _sfxPlayer.setVolume(0.5);
    }
  }
  
  bool get isMuted => _isMuted;
  
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}

enum SoundEffect {
  correctCell('correct_cell.mp3'),
  wrongCell('wrong_cell.mp3'),
  victory('victory.mp3'),
  artifact('artifact.mp3'),
  combo('combo.mp3'),
  star('star.mp3');
  
  final String path;
  const SoundEffect(this.path);
}