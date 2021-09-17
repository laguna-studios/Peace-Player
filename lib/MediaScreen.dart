import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:peace/AppCubit.dart';
import 'package:peace/main.dart';

import 'Models.dart';
import 'PlayerScreen.dart';

enum MediaType { ALBUM, ARTIST, PLAYLIST }

class MediaScreen extends StatelessWidget {
  final dynamic media;
  final MediaType mediaType;

  const MediaScreen({Key? key, required this.media, required this.mediaType})
      : super(key: key);

  SliverPersistentHeader _getAppBar(
      BuildContext context, int songCount, Function onPlayPressed) {
    return SliverPersistentHeader(
        delegate: MediaAppBar(
            MediaQuery.of(context).size.width / 2.5,
            media.name,
            songCount,
            () {
              switch (mediaType) {
                case MediaType.ALBUM:
                  AppCubit.of(context).toggleAlbumLike(media);
                  break;
                case MediaType.ARTIST:
                  AppCubit.of(context).toggleArtistLike(media);
                  break;
                case MediaType.PLAYLIST:
                  AppCubit.of(context).tooglePlaylistLike(media);
                  break;
              }
            },
            () {
              switch (mediaType) {
                case MediaType.ALBUM:
                  return AppCubit.of(context).albums.get(media.name)!.like;
                case MediaType.ARTIST:
                  return AppCubit.of(context).artists.get(media.name)!.like;
                case MediaType.PLAYLIST:
                  return AppCubit.of(context).playlists.get(media.name)!.like;
              }
            },
            onPlay: onPlayPressed,
            removeable: mediaType == MediaType.PLAYLIST,
            onRemove: () async {
              bool sure = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text("Are you sure?"),
                        content: Text("This will remove the playlist forever",
                            style: TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("No",
                                  style: TextStyle(color: Colors.redAccent))),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("Yes"))
                        ],
                      ));

              if (sure) {
                AppCubit.of(context).removePlaylist(media);
                Navigator.pop(context);
              }
            }));
  }

  static List<Song> getSongs(
      BuildContext context, MediaType mediaType, dynamic media) {
    switch (mediaType) {
      case MediaType.ALBUM:
        return AppCubit.of(context)
            .songs
            .values
            .where((element) => element.album == media.name)
            .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
      case MediaType.ARTIST:
        return AppCubit.of(context)
            .songs
            .values
            .where((element) => element.artist == media.name)
            .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
      case MediaType.PLAYLIST:
        Playlist playlist = media as Playlist;
        return AppCubit.of(context)
            .songs
            .values
            .where((element) => playlist.songs.contains(element.path))
            .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  static void playSongs(BuildContext context, List<Song> songs, int i) {
    AppCubit.of(context).onPlaySong(playlist: songs, index: i);
  }

  Widget getPlaylistDismissible(BuildContext context,
      {required Widget child, required Song song}) {
    return Slidable(
      child: child,
      actionExtentRatio: 0.3,
      actionPane: SlidableScrollActionPane(),
      secondaryActions: [
        IconSlideAction(
          caption: "Remove",
          color: Colors.redAccent,
          icon: Icons.delete,
          onTap: () {
            AppCubit.of(context).removeFromPlaylist(media, song);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Removed song from playlist"),
              action: SnackBarAction(
                label: "Undo",
                textColor: Colors.white,
                onPressed: () {
                  AppCubit.of(context).addToPlaylist(media, song);
                },
              ),
            ));
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final songs = getSongs(context, mediaType, media);
        return SafeArea(
            child: Scaffold(
          body: CustomScrollView(
            slivers: [
              _getAppBar(context, songs.length, () {
                AppCubit.of(context).onPlaySong(playlist: songs);
              }),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    var item = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0) Divider(color: Color(0xFF3a3a3a)),
                        MediaListItem(songs[i].name, songs[i].artist, () {
                          playSongs(context, songs.toList(), i);
                        }, likeable: false),
                      ],
                    );

                    if (mediaType != MediaType.PLAYLIST) return item;

                    return getPlaylistDismissible(context,
                        child: item, song: songs[i]);
                  },
                  childCount: songs.length,
                )),
              )
            ],
          ),
        ));
      },
    );
  }
}

class MediaAppBar extends SliverPersistentHeaderDelegate {
  final double imageWidth;
  final String name;
  final int songCount;
  final Function onPlay;
  final Function onLike;
  final bool Function() isLiked;
  final bool removeable;
  final Function? onRemove;

  get height => imageWidth + 80;

  MediaAppBar(
      this.imageWidth, this.name, this.songCount, this.onLike, this.isLiked,
      {required this.onPlay, this.removeable = false, this.onRemove})
      : assert(!removeable || onRemove != null);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final int hash = name.codeUnits
            .fold<int>(0, (previousValue, element) => previousValue + element) %
        THUMBNAIL_COUNT;
    return SizedBox(
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(CupertinoIcons.back)),
              elevation: 0,
              actions: removeable
                  ? [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => onRemove!(),
                      )
                    ]
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Center(
                    child: Hero(
                      tag: name,
                      child: ClipOval(
                        child: Image.asset(
                          "assets/$hash.jpg",
                          height: imageWidth,
                          width: imageWidth,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20)),
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, bottom: 10),
                        child: Text("$songCount Songs",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => onPlay(),
                            child: Text("Play",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor)),
                            style: ButtonStyle(
                                padding: MaterialStateProperty.resolveWith(
                                    (states) =>
                                        EdgeInsets.symmetric(horizontal: 30)),
                                backgroundColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.white),
                                shape: MaterialStateProperty.resolveWith(
                                    (states) => RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)))),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: BlocBuilder<AppCubit, AppState>(
                              builder: (context, state) =>
                                  LikeButton(onLike: onLike, isLiked: isLiked),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ));
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
