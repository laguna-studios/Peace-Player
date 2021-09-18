import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

void entrypoint() => AudioServiceBackground.run(() => BackgroundAudioService());

class BackgroundAudioService extends BackgroundAudioTask {
  static const String PLAY_SONG = "PLAY_SONG";
  static const String SEEK_TO_INDEX = "SEEK_TO_INDEX";
  static const String GET_FRESH_STATE = "GET_FRESH_STATE";

  final AudioPlayer _player = AudioPlayer();
  List<MediaItem> _mediaItemPlaylist = [];
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  @override
  Future<void> onPlay() async {
    AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext
      ],
      processingState: AudioProcessingState.ready,
      playing: true,
    );
    await _player.play();
  }

  @override
  Future<void> onPause() async {
    AudioServiceBackground.setState(controls: [
      MediaControl.skipToPrevious,
      MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop
    ], playing: false, processingState: AudioProcessingState.ready);
    await _player.pause();
  }

  @override
  Future<void> onSkipToNext() async {
    // ignore loop mode one if active
    if (_player.loopMode == LoopMode.one) {
      _player.setLoopMode(LoopMode.off);
      _player.seekToNext();
      _player.setLoopMode(LoopMode.one);
      return;
    }

    _player.seekToNext();
  }

  @override
  Future<void> onSkipToPrevious() async {
    // ignore loop mode one if active
    if (_player.loopMode == LoopMode.one) {
      _player.setLoopMode(LoopMode.off);
      _player.seekToPrevious();
      _player.setLoopMode(LoopMode.one);
      return;
    }

    _player.seekToPrevious();
  }

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    AudioServiceBackground.setState(
        controls: [MediaControl.play, MediaControl.stop],
        playing: false,
        processingState: AudioProcessingState.connecting);

    // connect to all player streams
    _player.currentIndexStream.listen((index) async {
      if (index == null || _mediaItemPlaylist.isEmpty) return;
      AudioServiceBackground.sendCustomEvent(
          [0, _mediaItemPlaylist[index].toJson()]);

      AudioServiceBackground.setMediaItem(
          _mediaItemPlaylist[index].copyWith(duration: _player.duration));
    });
    _player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: playerState.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState],
      );
    });

    _player.durationStream.listen(
        (e) => AudioServiceBackground.sendCustomEvent([1, e?.inSeconds]));
    _player.positionStream
        .listen((e) => AudioServiceBackground.setState(position: e));

    // load last playlist
    _player.setAudioSource(_playlist);
  }

  void _getFreshState() {
    //print("WWW push state");
    int? index = _player.currentIndex;
    //print("WWW current index: $index");
    if (index != null && _mediaItemPlaylist.isNotEmpty) {
      AudioServiceBackground.sendCustomEvent(
          [0, _mediaItemPlaylist[index].toJson()]);

      AudioServiceBackground.setMediaItem(
          _mediaItemPlaylist[index].copyWith(duration: _player.duration));
    }

    PlayerState playerState = _player.playerState;
    AudioServiceBackground.setState(
      playing: playerState.playing,
      // Every state from the audio player gets mapped onto an audio_service state.
      processingState: {
        ProcessingState.loading: AudioProcessingState.connecting,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[playerState.processingState],
    );

    Duration? duration = _player.duration;
    //print("WWW duration: $duration");
    if (duration != null) {
      AudioServiceBackground.sendCustomEvent([1, duration.inSeconds]);
    }

    Duration position = _player.position;
    //print("WWW position: $position");
    AudioServiceBackground.setState(position: position);
  }

  @override
  Future<void> onStop() {
    _player.stop();
    return super.onStop();
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    _player.seek(position);
  }

  @override
  Future<dynamic> onCustomAction(String name, arguments) async {
    switch (name) {
      case PLAY_SONG:
        List<MediaItem> playlist = List<MediaItem>.from(
            arguments["playlist"].map((e) => MediaItem.fromJson(e)));
        int index = arguments["index"];
        _updatePlaylist(playlist, index);
        break;
      case SEEK_TO_INDEX:
        int index = arguments["index"];
        await _player.pause();
        await _player.seek(Duration.zero, index: index);
        _player.play();
        break;
      case GET_FRESH_STATE:
        _getFreshState();
        break;
    }
  }

  Future<void> _updatePlaylist(List<MediaItem> playlist, int index) async {
    _mediaItemPlaylist = playlist;
    AudioServiceBackground.setQueue(playlist);
    await _player.pause();
    _playlist = ConcatenatingAudioSource(
        children:
            playlist.map((e) => AudioSource.uri(Uri.parse(e.id))).toList());
    await _player.setAudioSource(_playlist);
    await _player.seek(Duration.zero, index: index);
    onPlay();
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.all:
        _player.setShuffleModeEnabled(false);
        _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.one:
        _player.setShuffleModeEnabled(false);
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.none:
        _player.setShuffleModeEnabled(false);
        _player.setLoopMode(LoopMode.off);
        break;

      case AudioServiceRepeatMode.group:
        // shuffle impro
        _player.setShuffleModeEnabled(true);
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  // impro for volume
  @override
  Future<void> onSetSpeed(double volume) async {
    await _player.setVolume(volume);
  }
}
