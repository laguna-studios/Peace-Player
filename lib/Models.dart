import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
part 'Models.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String path;
  @HiveField(1)
  String name;
  @HiveField(2)
  String album;
  @HiveField(3)
  String artist;
  @HiveField(4)
  bool like;

  Song(this.path, this.name, this.album, this.artist, this.like);

  Song.fromMediaItem(MediaItem mediaItem)
      : this(mediaItem.id, mediaItem.title, mediaItem.album,
            mediaItem.artist ?? "", false);

  MediaItem toMediaItem() =>
      MediaItem(id: path, title: name, album: album, artist: artist);
}

@HiveType(typeId: 1)
class Album extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String artist;

  @HiveField(2)
  bool like;

  Album(this.name, this.artist, this.like);
}

@HiveType(typeId: 2)
class Artist extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  bool like;

  Artist(this.name, this.like);
}

@HiveType(typeId: 3)
class Playlist extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<String> songs;

  @HiveField(2)
  bool like;

  Playlist(this.name, this.songs, this.like);

  addSong(Song song) {
    if (!songs.contains(song.path)) {
      songs.add(song.path);
    }
  }

  removeSong(Song song) {
    songs.remove(song.path);
  }
}
