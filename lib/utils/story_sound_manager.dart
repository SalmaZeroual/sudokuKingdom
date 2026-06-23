import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class StorySoundManager {
  static final StorySoundManager _instance = StorySoundManager._internal();
  factory StorySoundManager() => _instance;
  StorySoundManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer   = AudioPlayer();

  bool _isMuted        = false;
  int? _currentKingdom; // évite de relancer la même piste

  // ─── Préférences ───────────────────────────────────────────────────────────

  Future<bool> _isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound_enabled') ?? true;
  }

  Future<bool> _isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibrations_enabled') ?? true;
  }

  // ─── Musique de fond ────────────────────────────────────────────────────────

  Future<void> playKingdomMusic(int kingdomId) async {
    if (_isMuted || !await _isSoundEnabled()) return;

    // Ne pas relancer la même piste si déjà en cours
    if (_currentKingdom == kingdomId &&
        _musicPlayer.state == PlayerState.playing) return;

    try {
      _currentKingdom = kingdomId;
      // Tes fichiers : kingdom1.mp3 ... kingdom5.mp3 (sans underscore)
      final path = 'audio/kingdom${kingdomId}.mp3';
      await _musicPlayer.setVolume(0.35);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(path));
    } catch (e) {
      // Fallback sur kingdom1 si le fichier du royaume n'existe pas
      try {
        await _musicPlayer.play(AssetSource('audio/kingdom1.mp3'));
      } catch (_) {}
      debugPrint('playKingdomMusic error: $e');
    }
  }

  Future<void> stopMusic() async {
    _currentKingdom = null;
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async => _musicPlayer.pause();
  Future<void> resumeMusic() async {
    if (!_isMuted && await _isSoundEnabled()) await _musicPlayer.resume();
  }

  // ─── Effets sonores ─────────────────────────────────────────────────────────

  Future<void> playSound(SoundEffect effect) async {
    if (_isMuted) return;

    final soundEnabled     = await _isSoundEnabled();
    final vibrationEnabled = await _isVibrationEnabled();

    // Son
    if (soundEnabled) {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.setVolume(0.8);
        await _sfxPlayer.play(AssetSource(effect.filename));
      } catch (e) {
        debugPrint('playSound error ${effect.filename}: $e');
      }
    }

    // Vibration
    if (vibrationEnabled && await Vibration.hasVibrator() == true) {
      _vibrate(effect);
    }
  }

  void _vibrate(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.correctCell:
        Vibration.vibrate(duration: 40, amplitude: 80);
        break;
      case SoundEffect.wrongCell:
        Vibration.vibrate(pattern: [0, 60, 60, 60]);
        break;
      case SoundEffect.victory:
        Vibration.vibrate(
          pattern: [0, 80, 40, 120, 40, 200],
        );
        break;
      case SoundEffect.artifact:
        Vibration.vibrate(duration: 180, amplitude: 120);
        break;
      case SoundEffect.combo:
        Vibration.vibrate(
          pattern: [0, 30, 30, 30, 30, 30],
        );
        break;
      case SoundEffect.star:
        Vibration.vibrate(
          pattern: [0, 60, 40, 100],
        );
        break;
    }
  }

  // ─── Mute ───────────────────────────────────────────────────────────────────

  void setMuted(bool muted) {
    _isMuted = muted;
    _musicPlayer.setVolume(muted ? 0 : 0.35);
    _sfxPlayer.setVolume(muted ? 0 : 0.8);
  }

  void toggleMute() => setMuted(!_isMuted);
  bool get isMuted => _isMuted;

  // ─── Cycle de vie ────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}

// ─── Enum avec les vrais noms de tes fichiers ─────────────────────────────────

enum SoundEffect {
  correctCell('audio/correct.mp3'),
  wrongCell('audio/wrong.mp3'),
  victory('audio/victory.mp3'),
  artifact('audio/artifact.mp3'),
  combo('audio/combo.mp3'),
  star('audio/star.mp3');

  final String filename;
  const SoundEffect(this.filename);
}