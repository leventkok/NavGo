import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceClip {
  const VoiceClip({
    required this.transcript,
    required this.duration,
    this.path,
  });

  final String transcript;
  final Duration duration;
  final String? path;
}

/// Device STT + TTS for plan chat voice notes.
///
/// Android gives the microphone to one client at a time, so recording and
/// speech recognition cannot run together. Recognition owns the mic here;
/// playback of the user's words uses TTS of the transcript.
class PlanVoice {
  PlanVoice();

  final _speech = SpeechToText();
  final _tts = FlutterTts();
  var _ready = false;
  String _draft = '';
  Stopwatch? _watch;

  Future<bool> ensureReady() async {
    if (_ready) return _speech.isAvailable;
    _ready = await _speech.initialize(
      onError: (error) {
        debugPrint('STT error: ${error.errorMsg} permanent=${error.permanent}');
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
      },
    );
    await _tts.awaitSpeakCompletion(false);
    return _ready;
  }

  Future<bool> startListening({
    required String localeCode,
    required void Function(String draft) onDraft,
  }) async {
    _draft = '';
    await _tts.stop();
    final ok = await ensureReady();
    if (!ok) return false;
    _watch = Stopwatch()..start();
    if (_speech.isListening) {
      await _speech.stop();
    }
    final localeId = await _resolveLocale(localeCode);
    try {
      await _speech.listen(
        onResult: (result) {
          _draft = result.recognizedWords.trim();
          onDraft(_draft);
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 8),
          localeId: localeId,
        ),
      );
    } catch (err) {
      debugPrint('STT listen failed: $err');
      return false;
    }
    return _speech.isListening;
  }

  Future<VoiceClip> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _watch?.stop();
    final duration = _watch?.elapsed ?? Duration.zero;
    _watch = null;
    final text = _draft.trim();
    _draft = '';
    return VoiceClip(transcript: text, duration: duration);
  }

  Future<void> speakCard(PlanSuggestion card, String localeCode) async {
    final line = [
      card.title,
      if (card.area.trim().isNotEmpty) card.area.trim(),
    ].join('. ');
    if (line.trim().isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage(_ttsLocale(localeCode));
    await _tts.setSpeechRate(0.48);
    await _tts.speak(line);
  }

  Future<void> speakText(String text, String localeCode) async {
    final line = text.trim();
    if (line.isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage(_ttsLocale(localeCode));
    await _tts.setSpeechRate(0.48);
    await _tts.speak(line);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    await _tts.stop();
  }

  Future<String> _resolveLocale(String code) async {
    final wanted = _sttLocale(code);
    try {
      final locales = await _speech.locales();
      debugPrint(
        'STT locales: ${locales.map((item) => item.localeId).join(',')}',
      );
      final codeLower = code.toLowerCase();
      final wantedLower = wanted.toLowerCase();
      for (final item in locales) {
        final id = item.localeId.toLowerCase().replaceAll('-', '_');
        final lang = id.split('_').first;
        if (lang == codeLower || id == wantedLower) {
          debugPrint('STT locale wanted=$wanted picked=${item.localeId}');
          return item.localeId;
        }
      }
    } catch (err) {
      debugPrint('STT locales failed: $err');
    }
    debugPrint('STT locale wanted=$wanted picked=$wanted (forced)');
    return wanted;
  }

  String _sttLocale(String code) {
    return switch (code) {
      'en' => 'en_US',
      'ru' => 'ru_RU',
      _ => 'tr_TR',
    };
  }

  String _ttsLocale(String code) {
    return switch (code) {
      'en' => 'en-US',
      'ru' => 'ru-RU',
      _ => 'tr-TR',
    };
  }
}
