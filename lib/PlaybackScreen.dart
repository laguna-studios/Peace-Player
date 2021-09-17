import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:peace/AppCubit.dart';
import 'package:peace/PlayerScreen.dart';

import 'Models.dart';
import 'main.dart';

class PlaybackScreen extends StatelessWidget {
  static const Map<AudioServiceRepeatMode, IconData> repeatMode2icon = {
    AudioServiceRepeatMode.none: Icons.trending_flat,
    AudioServiceRepeatMode.all: Icons.repeat,
    AudioServiceRepeatMode.one: Icons.repeat_one,
    AudioServiceRepeatMode.group: Icons.shuffle
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 24,
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14))),
      child: BlocBuilder<AppCubit, AppState>(
        builder: (BuildContext context, AppState state) {
          final int hash = state.currentMediaItem!.title.codeUnits.fold<int>(
                  0, (previousValue, element) => previousValue + element) %
              THUMBNAIL_COUNT;

          return Column(
            children: [
              Spacer(flex: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF303030),
                    borderRadius: BorderRadius.circular(8)),
              ),
              Spacer(flex: 8),
              ClipOval(
                child: Image.asset(
                  "assets/$hash.jpg",
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              Spacer(flex: 4),
              LimitedBox(
                maxHeight: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ((state.currentMediaItem?.title.length ?? 0) < 20)
                      ? Text(
                          state.currentMediaItem?.title ??
                              "Kein Song ausgewählt",
                          style: TextStyle(fontSize: 28),
                          maxLines: 1,
                        )
                      : Marquee(
                          text: state.currentMediaItem!.title,
                          style: TextStyle(fontSize: 28),
                          velocity: 20,
                          blankSpace: 20,
                        ),
                ),
              ),
              Spacer(),
              Text(state.currentMediaItem?.artist ?? "",
                  style: TextStyle(fontSize: 16)),
              Spacer(flex: 4),
              Stack(
                children: [
                  BlocBuilder<MediaPlaybackCubit, MediaPlaybackState>(
                      builder: (context, state) => Slider(
                            value: state.duration?.inSeconds.toDouble() == null
                                ? 0
                                : state.position?.inSeconds.toDouble() ?? 0,
                            onChangeEnd: (v) => AppCubit.of(context)
                                .onSeekTo(Duration(seconds: v.toInt())),
                            onChanged: (_) {},
                            min: 0,
                            max: state.duration?.inSeconds.toDouble() ?? 0,
                          )),
                  Positioned(
                    bottom: 0,
                    left: 22,
                    right: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BlocBuilder<MediaPlaybackCubit, MediaPlaybackState>(
                            builder: (context, state) =>
                                Text(state.positionString)),
                        BlocBuilder<MediaPlaybackCubit, MediaPlaybackState>(
                            builder: (context, state) =>
                                Text(state.durationString))
                      ],
                    ),
                  )
                ],
              ),
              Spacer(flex: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      onTap: AppCubit.of(context).toggleRepeatMode,
                      child: Icon(repeatMode2icon[state.repeatMode], size: 28)),
                  GestureDetector(
                      onTap: () => AppCubit.of(context).onSkipToPrevious(),
                      child: Icon(Icons.skip_previous, size: 28)),
                  GestureDetector(
                    onTap: () {
                      AppCubit.of(context).onTooglePlayback();
                    },
                    child: ColorIcon(
                      child: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28),
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                      size: 72,
                      shadow: true,
                    ),
                  ),
                  GestureDetector(
                      onTap: () => AppCubit.of(context).onSkipToNext(),
                      child: Icon(Icons.skip_next, size: 28)),
                  GestureDetector(
                      onTap: () => AppCubit.of(context).toggleVolume(),
                      child: Icon(
                          state.muted ? Icons.volume_off : Icons.volume_up,
                          size: 28)),
                ],
              ),
              Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                            onTap: () {
                              if (state.currentMediaItem == null) return;

                              showDialog(
                                  context: context,
                                  builder: (_) => AddToPlaylistDialog(
                                      song: Song.fromMediaItem(
                                          state.currentMediaItem!)));
                            },
                            child: Icon(Icons.add)),
                        GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              showModalBottomSheet(
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) {
                                    return QueueScreen();
                                  });
                            },
                            child: Icon(Icons.queue_music)),
                        LikeButton(onLike: () {
                          AppCubit.of(context).toggleSongLike(
                              Song.fromMediaItem(state.currentMediaItem!));
                        }, isLiked: () {
                          if (state.currentMediaItem == null) return false;
                          return AppCubit.of(context).isLiked(
                              Song.fromMediaItem(state.currentMediaItem!));
                        })
                      ],
                    ),
                  ),
                ),
              ),
              Spacer(flex: 4),
            ],
          );
        },
      ),
    );
  }
}

class PlaybackActionButton extends StatefulWidget {
  final double height;
  final double width;
  final Function onTap;

  const PlaybackActionButton(this.height, this.width, this.onTap, {Key? key})
      : super(key: key);

  @override
  _PlaybackActionButtonState createState() => _PlaybackActionButtonState();
}

class _PlaybackActionButtonState extends State<PlaybackActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coverRotationController;

  @override
  void initState() {
    super.initState();
    _coverRotationController =
        AnimationController(vsync: this, duration: Duration(seconds: 10));
    _coverRotationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listener: (context, state) {
        if (state.isPlaying && !_coverRotationController.isAnimating)
          _coverRotationController.repeat();
        else if (!state.isPlaying && _coverRotationController.isAnimating)
          _coverRotationController.stop();
      },
      builder: (BuildContext context, AppState state) {
        return GestureDetector(
          onTap: () => widget.onTap(),
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: widget.height * 0.9,
                    width: widget.width * 0.95,
                    decoration: BoxDecoration(
                        color: const Color(0xFF303030),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              offset: Offset(2, 2),
                              spreadRadius: 4,
                              blurRadius: 5)
                        ]),
                  ),
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0)
                              .animate(_coverRotationController),
                          child: ClipOval(
                            child: Image.asset("assets/single.png",
                                height: widget.height,
                                width: widget.height,
                                fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(
                            height: widget.height,
                            width: widget.height,
                            child: BlocBuilder<MediaPlaybackCubit,
                                MediaPlaybackState>(
                              builder: (context, state) =>
                                  CircularProgressIndicator(
                                value: state.progress,
                                color: Colors.deepPurple,
                                strokeWidth: 2,
                              ),
                            ))
                      ],
                    ),
                    SizedBox(width: 8),
                    LimitedBox(
                      maxWidth: widget.width -
                          widget.height -
                          (widget.height * 0.6) -
                          24,
                      child: (state.currentMediaItem!.title.length < 20)
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                state.currentMediaItem!.title,
                                style: TextStyle(fontSize: 16),
                                maxLines: 1,
                              ),
                            )
                          : Marquee(
                              text: state.currentMediaItem!.title,
                              style: TextStyle(fontSize: 16),
                              velocity: 20,
                              blankSpace: 20,
                            ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        AppCubit.of(context).onTooglePlayback();
                      },
                      child: ColorIcon(
                        child: Icon(
                            state.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: const Color(0xFF666666)),
                        color: Colors.white,
                        shape: BoxShape.circle,
                        size: widget.height * 0.6,
                      ),
                    ),
                    SizedBox(width: 8)
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QueueScreen extends StatefulWidget {
  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    int i = AudioService.queue?.indexWhere(
            (element) => element.id == AudioService.currentMediaItem?.id) ??
        0;
    _scrollController = ScrollController(initialScrollOffset: i * 72);
    //_scrollController.jumpTo(i);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14))),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child:
                Text("Current Playlist", style: PlayerScreen.welcomeTextStyle),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: StreamBuilder<List<MediaItem>?>(
                  initialData: AudioService.queue,
                  stream: AudioService.queueStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null)
                      return Container();

                    List<MediaItem> songs = snapshot.data!;

                    return ListView.builder(
                        controller: _scrollController,
                        itemCount: songs.length,
                        itemBuilder: (context, i) {
                          return MediaListItem(
                            songs[i].title,
                            songs[i].artist!,
                            () => AppCubit.of(context).seekToIndex(i),
                            likeable: false,
                          );
                        });
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

class AddToPlaylistDialog extends StatelessWidget {
  final Song song;

  const AddToPlaylistDialog({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Playlist> playlists = AppCubit.of(context).playlists.values.toList();

    return AlertDialog(
      title: Text("Add to playlist"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.4,
        child: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text(playlists[i].name,
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  AppCubit.of(context).addToPlaylist(playlists[i], song);
                  Navigator.pop(context);
                },
              );
            }),
      ),
      actions: [
        TextButton(
            onPressed: () => showDialog(
                context: context, builder: (_) => AddPlaylistDialog()),
            child: Text("New Playlist")),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.redAccent),
            ))
      ],
    );
  }
}

class AddPlaylistDialog extends StatefulWidget {
  @override
  _AddPlaylistDialogState createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("New Playlist"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            maxLines: 1,
            maxLength: 30,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                counterText: "",
                hintText: "Name",
                hintStyle: TextStyle(color: Colors.white54),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.white54)),
            controller: _controller,
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.redAccent))),
        TextButton(
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                AppCubit.of(context).addPlaylist(_controller.text);
              }

              Navigator.pop(context);
            },
            child: Text("Create")),
      ],
    );
  }
}
