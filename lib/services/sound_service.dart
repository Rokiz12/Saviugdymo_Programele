import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playHappyDiary() async { // done
    await _player.play(AssetSource('sounds/diaryHappy.mp3'));
  }

  static Future<void> playMarkHabit() async { // done
    await _player.play(AssetSource('sounds/check.mp3'));
  }

  static Future<void> palyClaimReward() async { // done
    await _player.play(AssetSource('sounds/reward.mp3'));
  }



  static Future<void> playSadDiary() async { // done
    await _player.play(AssetSource('sounds/diarySad.mp3'));
  }

  static Future<void> playCat() async {
    await _player.play(AssetSource('sounds/cat.mp3'));
  }

  static Future<void> playCock() async {
    await _player.play(AssetSource('sounds/cock.mp3'));
  }

  static Future<void> playDeleteHabit() async { // done
    await _player.play(AssetSource('sounds/deleteHabit.mp3'));
  }

  static Future<void> playMouse() async {
    await _player.play(AssetSource('sounds/mouse.mp3'));
  }

  static Future<void> playWorm() async {
    await _player.play(AssetSource('sounds/worm.mp3'));
  }
}