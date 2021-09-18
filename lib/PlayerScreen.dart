import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:peace/AdsCubit.dart';
import 'package:peace/MediaScreen.dart';
import 'package:peace/AppCubit.dart';
import 'package:peace/PlaybackScreen.dart';
import 'package:peace/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Models.dart';

class PlayerScreen extends StatefulWidget {
  static const welcomeTextStyle = const TextStyle(fontSize: 24);
  static const subTitleTextStyle = const TextStyle(fontSize: 20);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String? search;

  String _getHeader2(SelectedTab selectedTab) {
    switch (selectedTab) {
      case SelectedTab.SONG:
        return "All Songs";
      case SelectedTab.ALBUM:
        return "All Albums";
      case SelectedTab.ARTIST:
        return "All Artists";
      case SelectedTab.PLAYLIST:
        return "All Playlists";
    }
  }

  Future<dynamic> _openMedia(
      BuildContext context, dynamic media, MediaType mediaType) async {
    return await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MediaScreen(
                  media: media,
                  mediaType: mediaType,
                )));
  }

  bool _fitsSearch(dynamic media) {
    return search == null ||
        media.name.toLowerCase().contains(search!.toLowerCase());
  }

  bool _fitsSearchAndLike(dynamic media) {
    return media.like &&
        (search == null ||
            media.name.toLowerCase().contains(search!.toLowerCase()));
  }

  int _sort(a, b) => a.name.compareTo(b.name);

  List<dynamic> _getDataSourceAll(
      BuildContext context, SelectedTab selectedTab) {
    switch (selectedTab) {
      case SelectedTab.SONG:
        return AppCubit.of(context).songs.values.where(_fitsSearch).toList()
          ..sort(_sort);
      case SelectedTab.ALBUM:
        return AppCubit.of(context).albums.values.where(_fitsSearch).toList()
          ..sort(_sort);
      case SelectedTab.ARTIST:
        return AppCubit.of(context).artists.values.where(_fitsSearch).toList()
          ..sort(_sort);
      case SelectedTab.PLAYLIST:
        return AppCubit.of(context).playlists.values.where(_fitsSearch).toList()
          ..sort(_sort);
    }
  }

  List<dynamic> _getDataSourceFavorites(
      BuildContext context, SelectedTab selectedTab) {
    switch (selectedTab) {
      case SelectedTab.SONG:
        return AppCubit.of(context)
            .songs
            .values
            .where(_fitsSearchAndLike)
            .toList();
      case SelectedTab.ALBUM:
        return AppCubit.of(context)
            .albums
            .values
            .where(_fitsSearchAndLike)
            .toList();
      case SelectedTab.ARTIST:
        return AppCubit.of(context)
            .artists
            .values
            .where(_fitsSearchAndLike)
            .toList();
      case SelectedTab.PLAYLIST:
        return AppCubit.of(context)
            .playlists
            .values
            .where(_fitsSearchAndLike)
            .toList();
    }
  }

  Widget _getMediaItem(
      BuildContext context, SelectedTab selectedTab, dynamic item, int index,
      {List<Song> playlist = const []}) {
    switch (selectedTab) {
      case SelectedTab.SONG:
        Song song = item as Song;
        return MediaListItem(song.name, song.artist, () {
          AppCubit.of(context).onPlaySong(playlist: playlist, index: index);
        }, onLike: () {
          AppCubit.of(context).toggleSongLike(song);
        }, isLiked: () => song.like);
      case SelectedTab.ALBUM:
        Album album = item as Album;
        return MediaListItem(
          album.name,
          album.artist,
          () {
            _openMedia(context, album, MediaType.ALBUM);
          },
          onLike: () {
            AppCubit.of(context).toggleAlbumLike(album);
          },
          isLiked: () => album.like,
        );
      case SelectedTab.ARTIST:
        Artist artist = item as Artist;
        return MediaListItem(artist.name, "", () {
          _openMedia(context, artist, MediaType.ARTIST);
        }, onLike: () {
          AppCubit.of(context).toggleArtistLike(artist);
        }, isLiked: () => artist.like);
      case SelectedTab.PLAYLIST:
        Playlist playlist = item as Playlist;
        return MediaListItem(
          playlist.name,
          "${playlist.songs.length} songs",
          () {
            _openMedia(context, item, MediaType.PLAYLIST);
          },
          onLike: () => AppCubit.of(context).tooglePlaylistLike(playlist),
          isLiked: () => playlist.like,
        );
    }
  }

  Widget _getMediaCard(
      BuildContext context, SelectedTab selectedTab, dynamic item, int index) {
    switch (selectedTab) {
      case SelectedTab.SONG:
        Song song = item as Song;
        return MediaCard(
            () {
              AppCubit.of(context).onPlaySong(
                  playlist: _getDataSourceFavorites(context, selectedTab)
                      as List<Song>,
                  index: index);
            },
            song.name,
            song.artist,
            () {
              AppCubit.of(context).onPlaySong(
                  playlist: _getDataSourceFavorites(context, selectedTab)
                      as List<Song>,
                  index: index);
            });
      case SelectedTab.ALBUM:
        Album album = item as Album;
        return MediaCard(
            () {
              _openMedia(context, album, MediaType.ALBUM);
            },
            album.name,
            album.artist,
            () {
              MediaScreen.playSongs(context,
                  MediaScreen.getSongs(context, MediaType.ALBUM, album), 0);
            });
      case SelectedTab.ARTIST:
        Artist artist = item as Artist;
        return MediaCard(
            () {
              _openMedia(context, artist, MediaType.ARTIST);
            },
            artist.name,
            "",
            () {
              MediaScreen.playSongs(context,
                  MediaScreen.getSongs(context, MediaType.ARTIST, artist), 0);
            });
      case SelectedTab.PLAYLIST:
        Playlist playlist = item as Playlist;
        return MediaCard(
            () {
              _openMedia(context, playlist, MediaType.PLAYLIST);
            },
            playlist.name,
            "${playlist.songs.length} songs",
            () {
              MediaScreen.playSongs(
                  context,
                  MediaScreen.getSongs(context, MediaType.PLAYLIST, playlist),
                  0);
            });
    }
  }

  Widget _getDrawer(BuildContext context) {
    return Drawer(
      child: Container(
          color: Color(0xFF222222),
          child: Column(
            children: [
              Image.asset("assets/drawer.jpg"),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Icon(Icons.refresh, color: Colors.white),
                      title: Text("Update Your Library",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        AppCubit.of(context).refreshDatabase();
                        Navigator.pop(context);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text("More", style: TextStyle(fontSize: 16)),
                    ),
                    Divider(
                      color: Colors.white,
                      endIndent: 8,
                      indent: 8,
                    ),
                    ListTile(
                      leading: Icon(Icons.favorite, color: Colors.white),
                      title: Text("Like App",
                          style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        _like();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.star, color: Colors.white),
                      title: Text("Get Pro Version",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _launch(
                            "https://play.google.com/store/apps/details?id=org.seniorlaguna.peacepro");
                        Navigator.pop(context);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text("Legal", style: TextStyle(fontSize: 16)),
                    ),
                    Divider(
                      color: Colors.white,
                      endIndent: 8,
                      indent: 8,
                    ),
                    ListTile(
                      dense: true,
                      title:
                          Text("About", style: TextStyle(color: Colors.white)),
                      onTap: () => showAboutDialog(
                          context: context,
                          applicationIcon: Image.asset("assets/icon/icon.png",
                              height: 50, width: 50),
                          applicationLegalese:
                              "A big thank you goes to all creators at unsplash.com, dribble.com and flaticon.com!",
                          applicationVersion: "1.0.0"),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Contact",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _launch("https://seniorlaguna.github.io/contact.html");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Terms Of Use",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _launch(
                            "https://seniorlaguna.github.io/peace-player/terms.html");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Privacy Policy",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _launch(
                            "https://seniorlaguna.github.io/peace-player/privacy.html");
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Future<void> _like() {
    return _launch(
        "https://play.google.com/store/apps/details?id=org.seniorlaguna.peace");
  }

  Future<void> _launch(String url) async {
    await canLaunch(url) && await launch(url);
  }

  void _toggleDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _askForRating(BuildContext context) {
    LikeDialog.show(context, onLike: _like);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        // not initialized yet
        if (!state.initialized) return WaitScreen();

        List<dynamic> items = _getDataSourceAll(context, state.selectedTab);
        List<dynamic> likes =
            _getDataSourceFavorites(context, state.selectedTab);

        return BlocListener<AdsCubit, AdsState>(
          listenWhen: (old, now) => now.like && !old.like,
          listener: (context, _) => _askForRating(context),
          child: SafeArea(
            child: Scaffold(
              drawer: _getDrawer(context),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: state.currentMediaItem == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: PlaybackActionButton(
                        80,
                        MediaQuery.of(context).size.width * 0.9,
                        () {
                          showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (context) {
                                return PlaybackScreen();
                              });
                        },
                      ),
                    ),
              body: Builder(
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 50,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: IconButton(
                                          icon: Icon(Icons.menu),
                                          onPressed: () =>
                                              _toggleDrawer(context),
                                        ),
                                      ),
                                      Text(
                                        "Peace Player",
                                        style: PlayerScreen.welcomeTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    right: 0,
                                    child: SearchButton(onSearch: (search) {
                                      setState(() {
                                        this.search = search;
                                      });
                                    }))
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          sliver: SliverPersistentHeader(
                            delegate: SwitchBar(),
                            floating: true,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Text("Favorites",
                              style: PlayerScreen.subTitleTextStyle),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          sliver: SliverToBoxAdapter(
                              child: SizedBox(
                            height: 200,
                            child: likes.isEmpty
                                ? Center(child: Text("No favorites yet"))
                                : ListView.builder(
                                    itemCount: likes.length,
                                    itemBuilder: (context, i) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: _getMediaCard(context,
                                              state.selectedTab, likes[i], i),
                                        ),
                                    scrollDirection: Axis.horizontal),
                          )),
                        ),
                        SliverToBoxAdapter(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: BlocBuilder<AdsCubit, AdsState>(
                              builder: (context, adsState) {
                            // not ready yet
                            if (!adsState.isReady(state.selectedTab)) {
                              return Container(
                                height: 0,
                              );
                            }

                            return SizedBox(
                              height: 50,
                              child: AdWidget(
                                  ad: AdsCubit.of(context)
                                      .getBanner(state.selectedTab)),
                            );
                          }),
                        )),
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverToBoxAdapter(
                            child: Text(_getHeader2(state.selectedTab),
                                style: PlayerScreen.subTitleTextStyle),
                          ),
                        ),
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i > 0) Divider(color: Color(0xFF3a3a3a)),
                                i == items.length
                                    ? SizedBox(height: 100)
                                    : _getMediaItem(
                                        context, state.selectedTab, items[i], i,
                                        playlist: (state.selectedTab ==
                                                SelectedTab.SONG)
                                            ? items as List<Song>
                                            : []),
                              ],
                            );
                          },
                          childCount: items.length + 1,
                        ))
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaitScreen extends StatelessWidget {
  const WaitScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Please wait... First start up might take a bit longer 😀",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MediaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Function onTap;
  final Function onPlay;

  const MediaCard(this.onTap, this.title, this.subtitle, this.onPlay,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int hash = title.codeUnits
            .fold<int>(0, (previousValue, element) => previousValue + element) %
        THUMBNAIL_COUNT;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          width: 150,
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: Hero(
                  tag: title,
                  child: Image.asset(
                    "assets/$hash.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF303030),
                width: 150,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LimitedBox(
                        maxWidth: 110,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white)),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFFc2c2c2)))
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onPlay(),
                        child: ColorIcon(
                          child: Icon(
                            Icons.play_arrow,
                            color: const Color(0xFF666666),
                            size: 16,
                          ),
                          color: Colors.white,
                          size: 24,
                          shape: BoxShape.circle,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaListItem extends StatelessWidget {
  final String title;
  final String subTitle;
  final Function onTap;
  final bool likeable;
  final Function? onLike;
  final bool Function()? isLiked;

  const MediaListItem(this.title, this.subTitle, this.onTap,
      {Key? key, this.likeable = true, this.onLike, this.isLiked})
      : assert(!likeable || onLike != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      contentPadding: EdgeInsets.zero,
      leading: Image.asset("assets/single.png"),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(
        subTitle,
        style: TextStyle(color: Color(0xFFb0b0b0)),
      ),
      trailing:
          likeable ? LikeButton(onLike: onLike!, isLiked: isLiked!) : null,
    );
  }
}

class LikeButton extends StatelessWidget {
  const LikeButton(
      {Key? key,
      required this.onLike,
      required this.isLiked,
      this.iconSize = 24,
      this.background = true})
      : super(key: key);

  final Function onLike;
  final bool Function() isLiked;
  final double iconSize;
  final bool background;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onLike(),
      child: ColorIcon(
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) => Icon(
            isLiked() ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        shape: BoxShape.circle,
        color: Color(0xFF303030),
        size: iconSize + 15,
      ),
    );
  }
}

class SwitchBar extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SwitchButton<SelectedTab>(
      ["Song", "Album", "Artist", "Playlist"],
      [
        SelectedTab.SONG,
        SelectedTab.ALBUM,
        SelectedTab.ARTIST,
        SelectedTab.PLAYLIST
      ],
      AppCubit.of(context).changeTab,
      selectionColor: Colors.white,
      selectedTextStyle: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor, fontSize: 16),
      defaultTextStyle: TextStyle(color: Color(0xFFb0b0b0), fontSize: 16),
      itemHeight: 40,
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class SwitchButton<T> extends StatefulWidget {
  final List<String> children;
  final List<T> callbackParams;
  final Function onSelected;

  /// optional params
  final int defaultIndex;
  final double borderRadius;
  final Color selectionColor;
  final TextStyle defaultTextStyle;
  final TextStyle selectedTextStyle;
  final double itemHeight;
  final double itemWidth;
  final bool enabled;

  /// lengths of callback params must equal number of children
  const SwitchButton(this.children, this.callbackParams, this.onSelected,
      {Key? key,
      this.defaultIndex = 0,
      this.borderRadius = 64,
      this.selectionColor = Colors.green,
      this.defaultTextStyle = const TextStyle(
        fontSize: 14,
      ),
      this.selectedTextStyle =
          const TextStyle(fontSize: 16, color: Colors.white),
      this.itemHeight = 40,
      this.itemWidth = 80,
      this.enabled = true})
      : assert(children.length == callbackParams.length),
        super(key: key);

  @override
  _SwitchButtonState createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.defaultIndex;
  }

  void _changeIndex(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      //borderRadius: BorderRadius.circular(widget.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            AnimatedPositioned(
              left: index * widget.itemWidth,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOutQuad,
              child: Container(
                width: widget.itemWidth,
                height: widget.itemHeight,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    color: widget.enabled
                        ? widget.selectionColor
                        : Colors.grey.shade400),
              ),
            ),
            Wrap(
              children: [
                for (int i = 0; i < widget.children.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (!widget.enabled) return;
                      _changeIndex(i);
                      widget.onSelected(widget.callbackParams[i]);
                    },
                    child: SizedBox(
                        width: widget.itemWidth,
                        height: widget.itemHeight,
                        child: Center(
                            child: Text(
                          widget.children[i],
                          style: index == i
                              ? widget.selectedTextStyle
                              : widget.defaultTextStyle,
                        ))),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColorIcon extends StatelessWidget {
  final Widget child;

  final double size;
  final double borderRadius;
  final Color color;
  final BoxShape shape;
  final bool shadow;

  const ColorIcon(
      {Key? key,
      required this.child,
      this.size = 50,
      this.borderRadius = 8,
      this.color = const Color(0xff229A4C),
      this.shape = BoxShape.rectangle,
      this.shadow = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            boxShadow: shadow
                ? [BoxShadow(blurRadius: 60, color: Colors.deepPurple)]
                : null,
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.circle
                ? null
                : BorderRadius.circular(borderRadius)),
        child: Center(child: child));
  }
}

class SearchButton extends StatefulWidget {
  final Function(String? search) onSearch;

  const SearchButton({Key? key, required this.onSearch}) : super(key: key);

  @override
  _SearchButtonState createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton> {
  bool searching = false;
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        decoration: BoxDecoration(
            color: Color(0xFF303030), borderRadius: BorderRadius.circular(8)),
        width: searching ? MediaQuery.of(context).size.width - 24 : 50,
        height: 50,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCirc,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (searching)
            Expanded(
                child: TextField(
                    autofocus: true,
                    onChanged: widget.onSearch,
                    onSubmitted: widget.onSearch,
                    controller: _controller,
                    style: TextStyle(color: Colors.white),
                    maxLines: 1,
                    maxLength: 30,
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding: const EdgeInsets.only(left: 8),
                      hintText: "Search...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ))),
          GestureDetector(
            onTap: () {
              setState(() {
                if (searching) {
                  widget.onSearch(null);
                  _controller.clear();
                }
                searching = !searching;
              });
            }, //AppCubit.of(context).refreshDatabase,
            child: Padding(
              padding: EdgeInsets.only(
                  right: (50 - (Theme.of(context).iconTheme.size ?? 24)) / 2),
              child: Icon(
                searching ? Icons.cancel_outlined : Icons.search,
                color: Colors.white,
              ),
            ),
          )
        ]));
  }
}

class LikeDialog extends StatelessWidget {
  final Function onLike;

  /// convenience method
  static Future<void> show(BuildContext context, {required Function onLike}) =>
      showDialog(context: context, builder: (_) => LikeDialog(onLike: onLike));

  const LikeDialog({Key? key, required this.onLike}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("We need your feedback!"),
      content: Text(
          "We would love to hear what you think about Peace Player :)",
          style: TextStyle(fontSize: 16)),
      actions: [
        TextButton(
            onPressed: () {
              onLike();
              Navigator.pop(context);
            },
            child: Text("Let's go")),
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text("Nope")),
      ],
    );
  }
}
