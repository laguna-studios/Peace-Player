import 'dart:io';

import 'package:audio_info/audio_info.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart';
import 'package:external_path/external_path.dart';

import 'BackgroundAudioService.dart';
import 'Models.dart';

enum SelectedTab { SONG, ALBUM, ARTIST, PLAYLIST }

class AppState extends Equatable {
  final MediaItem? currentMediaItem;
  final bool isPlaying;
  final SelectedTab selectedTab;
  final bool initialized;
  final bool changed;
  final AudioServiceRepeatMode repeatMode;
  final bool muted;

  AppState(
      this.currentMediaItem, this.isPlaying, this.initialized, this.repeatMode,
      {this.selectedTab = SelectedTab.SONG,
      this.changed = false,
      this.muted = false});

  AppState copyWith(
      {List<MediaItem>? songs,
      MediaItem? currentMediaItem,
      bool? isPlaying,
      SelectedTab? selectedTab,
      bool? initialized,
      bool? changed,
      AudioServiceRepeatMode? repeatMode,
      bool? muted}) {
    return AppState(
        currentMediaItem ?? this.currentMediaItem,
        isPlaying ?? this.isPlaying,
        initialized ?? this.initialized,
        repeatMode ?? this.repeatMode,
        selectedTab: selectedTab ?? this.selectedTab,
        changed: changed ?? this.changed,
        muted: muted ?? this.muted);
  }

  AppState change() => copyWith(changed: !changed);

  @override
  List<Object?> get props => [
        currentMediaItem,
        isPlaying,
        selectedTab,
        initialized,
        changed,
        repeatMode,
        muted
      ];
}

class AppCubit extends Cubit<AppState> {
  late Box settings;
  late Box<Song> songs;
  late Box<Album> albums;
  late Box<Artist> artists;
  late Box<Playlist> playlists;

  /// settings keys
  static const String SETTINGS_REPEAT_MODE = "repeatMode";
  static const String SETTINGS_FIRST_START = "firstStart";

  AppCubit()
      : super(AppState(null, false, false, AudioServiceRepeatMode.none)) {
    _init();
  }

  static AppCubit of(BuildContext context) =>
      BlocProvider.of<AppCubit>(context);

  @override
  Future<void> close() async {
    AudioService.disconnect();
    settings.close();
    songs.close();
    albums.close();
    artists.close();
    playlists.close();
    super.close();
  }

  Future<void> _init() async {
    await _startBackgroundService();
    await _initDatabase();
    await _initPlayer();
    _getFreshState();
  }

  void _onCustomEvent(dynamic event) {
    // is no update media item event
    if (event == null || event[0] != 0) return;

    _onCurrentMediaItemChanged(
        MediaItem.fromJson(Map<String, dynamic>.from(event[1])));
  }

  void _onCurrentMediaItemChanged(MediaItem mediaItem) {
    print("new media item: $mediaItem");
    emit(state.copyWith(currentMediaItem: mediaItem));
  }

  void _onPlaybackStateChanged(PlaybackState? playbackState) {
    emit(state.copyWith(isPlaying: playbackState?.playing));
  }

  Future<void> _startBackgroundService() async {
    bool connected = false;
    while (!connected) {
      try {
        connected = AudioService.connected;
      } catch (e) {
        print("Error checking connection");
      }

      if (!connected) {
        await AudioService.connect();
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    await AudioService.start(backgroundTaskEntrypoint: entrypoint);
    AudioService.customEventStream.listen(_onCustomEvent);
    AudioService.playbackStateStream.listen(_onPlaybackStateChanged);
  }

  Future<void> _getFreshState() async {
    AudioService.customAction(BackgroundAudioService.GET_FRESH_STATE);
  }

  bool _isSupportedAudio(String path) {
    var suffix = path.split(".").last;
    return ["mp3", "wav", "m4a"].contains(suffix);
  }

  Future<void> _initDatabase() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(AlbumAdapter());
    Hive.registerAdapter(ArtistAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    settings = await Hive.openBox("settings");
    songs = await Hive.openBox("songs");
    albums = await Hive.openBox("albums");
    artists = await Hive.openBox("artists");
    playlists = await Hive.openBox("playlists");

    // on first start populate database
    if (settings.get(SETTINGS_FIRST_START, defaultValue: true)) {
      await refreshDatabase();
      settings.put(SETTINGS_FIRST_START, false);
    }

    emit(state.copyWith(initialized: true));
  }

  Future<void> _initPlayer() async {
    int repeatMode = settings.get(SETTINGS_REPEAT_MODE, defaultValue: 0);
    toggleRepeatMode(next: repeatMode);
  }

  Future<void> refreshDatabase() async {
    // songs.clear();
    // albums.clear();
    // artists.clear();

    List<Directory> dirsToCheck =
        (await ExternalPath.getExternalStorageDirectories())
            .map((e) => Directory(e))
            .toList();

    while (dirsToCheck.isNotEmpty) {
      var dir = dirsToCheck.removeAt(0);

      // skip directory
      if (File(join(dir.path, ".nomedia")).existsSync()) break;

      for (var entity in dir.listSync()) {
        switch (entity.statSync().type) {
          case FileSystemEntityType.directory:
            dirsToCheck.add(Directory(entity.path));
            break;
          case FileSystemEntityType.file:
            if (_isSupportedAudio(entity.path)) {
              try {
                Map<String, String?> metadata =
                    await AudioInfo.getAudioMetadata(entity.path);

                //print(metadata);

                Song song = Song(
                    entity.path,
                    metadata["title"] ??
                        "${entity.path.split("/").last.split("\.").first}",
                    metadata["album"] ?? "Unknown Album",
                    metadata["artist"] ?? "Unknown Artist",
                    false);

                songs.put(song.path, song);
                albums.put(song.album, Album(song.album, song.artist, false));
                artists.put(song.artist, Artist(song.artist, false));
              } catch (e, s) {
                print("skipping : ${entity.path}");
                print(s);
              }
            }
            break;
        }
      }

      emit(state.change());
    }

    // remove songs that arent available anymore
    songs.deleteAll(songs.values
        .where((element) => !File(element.path).existsSync())
        .map((e) => e.path));

    // remove all albums without any songs in it
    albums.deleteAll(albums.values
        .where((album) => !songs.values.any((song) => song.album == album.name))
        .map((album) => album.name));

    // remove all artists without songs
    artists.deleteAll(artists.values
        .where(
            (artist) => !songs.values.any((song) => song.artist == artist.name))
        .map((artist) => artist.name));
  }

  void changeTab(SelectedTab selectedTab) {
    emit(state.copyWith(selectedTab: selectedTab));
  }

  Future<void> onSeekTo(Duration duration) async {
    AudioService.seekTo(duration);
  }

  Future<void> onTooglePlayback() async {
    await _startBackgroundService();
    state.isPlaying ? AudioService.pause() : AudioService.play();
  }

  Future<void> onSkipToNext() async {
    await _startBackgroundService();
    AudioService.skipToNext();
  }

  Future<void> onSkipToPrevious() async {
    await _startBackgroundService();
    AudioService.skipToPrevious();
  }

  Future<void> onPlaySong({required List<Song> playlist, int index = 0}) async {
    await _startBackgroundService();

    AudioService.customAction(BackgroundAudioService.PLAY_SONG, {
      "playlist": playlist.map((e) => e.toMediaItem().toJson()).toList(),
      "index": index
    });

    // no stream event bug
    if (index == 0) _getFreshState();
  }

  bool isLiked(Song? song) {
    if (song == null) return false;
    return songs.get(song.path)!.like;
  }

  void toggleSongLike(Song? song) {
    if (song == null) return;

    song = songs.get(song.path)!;
    song.like = !song.like;
    song.save();

    emit(state.change());
  }

  void toggleAlbumLike(Album? album) {
    if (album == null) return;
    album.like = !album.like;
    album.save();

    emit(state.change());
  }

  void toggleArtistLike(Artist? artist) {
    if (artist == null) return;
    artist.like = !artist.like;
    artist.save();

    emit(state.change());
  }

  void tooglePlaylistLike(Playlist? playlist) {
    if (playlist == null) return;

    playlist.like = !playlist.like;
    playlist.save();

    emit(state.change());
  }

  Playlist addPlaylist(String name) {
    playlists.put(name, Playlist(name, [], false));
    emit(state.change());
    return playlists.get(name)!;
  }

  void removePlaylist(Playlist? playlist) {
    if (playlist == null) return;
    playlists.delete(playlist.name);
    emit(state.change());
  }

  void addToPlaylist(Playlist? playlist, Song? song) {
    if (playlist == null || song == null) return;
    playlist.addSong(song);
    playlist.save();

    emit(state.change());
  }

  void removeFromPlaylist(Playlist? playlist, Song? song) {
    if (playlist == null || song == null) return;
    playlist.removeSong(song);
    playlist.save();

    emit(state.change());
  }

  void toggleRepeatMode({int? next}) {
    var modes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.group
    ];

    AudioServiceRepeatMode nextMode =
        modes[next ?? (modes.indexOf(state.repeatMode) + 1) % 4];
    AudioService.setRepeatMode(nextMode);

    // save repeat mode
    settings.put(SETTINGS_REPEAT_MODE, modes.indexOf(nextMode));
    emit(state.copyWith(repeatMode: nextMode));
  }

  void seekToIndex(int index) {
    AudioService.customAction(
        BackgroundAudioService.SEEK_TO_INDEX, {"index": index});
  }

  void toggleVolume() {
    AudioService.setSpeed(state.muted ? 1 : 0);
    emit(state.copyWith(muted: !state.muted));
  }
}

class MediaPlaybackState extends Equatable {
  final Duration? position;
  final Duration? duration;

  double get progress => (position == null || duration == null)
      ? 0
      : position!.inSeconds / duration!.inSeconds;

  String get positionString => position == null
      ? "--:--"
      : "${position!.inMinutes.toString().padLeft(2, "0")}:${(position!.inSeconds % 60).toString().padLeft(2, "0")}";

  String get durationString => duration == null
      ? "--:--"
      : "${duration!.inMinutes.toString().padLeft(2, "0")}:${(duration!.inSeconds % 60).toString().padLeft(2, "0")}";

  MediaPlaybackState({this.position, this.duration});

  MediaPlaybackState updatePosition(Duration? position) =>
      MediaPlaybackState(position: position, duration: duration);

  MediaPlaybackState updateDuration(Duration? duration) =>
      MediaPlaybackState(position: Duration.zero, duration: duration);

  @override
  List<Object?> get props => [position, duration];
}

class MediaPlaybackCubit extends Cubit<MediaPlaybackState> {
  MediaPlaybackCubit() : super(MediaPlaybackState()) {
    AudioService.positionStream
        .listen((position) => emit(state.updatePosition(position)));
    AudioService.customEventStream.listen(_onCustomEvent);
  }

  void _onCustomEvent(dynamic event) {
    // is not a update duration event
    if (event == null || event[0] != 1 || event[1] == null) return;

    emit(state.updateDuration(Duration(seconds: event[1])));
  }
}
