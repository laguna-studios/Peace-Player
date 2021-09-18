import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:peace/AppCubit.dart';

class AdsState extends Equatable {
  final bool test;
  final bool songs;
  final bool albums;
  final bool artists;
  final bool playlists;
  final bool like;

  AdsState(this.test, this.songs, this.albums, this.artists, this.playlists,
      this.like);

  bool isReady(SelectedTab selectedTab) {
    // for testing
    return test;

    switch (selectedTab) {
      case SelectedTab.SONG:
        return songs;
      case SelectedTab.ALBUM:
        return albums;
      case SelectedTab.ARTIST:
        return artists;
      case SelectedTab.PLAYLIST:
        return playlists;
    }
  }

  AdsState copyWith(
          {bool? test,
          bool? songs,
          bool? albums,
          bool? artists,
          bool? playlists,
          bool? like}) =>
      AdsState(
          test ?? this.test,
          songs ?? this.songs,
          albums ?? this.albums,
          artists ?? this.artists,
          playlists ?? this.playlists,
          like ?? this.like);

  @override
  List<Object?> get props => [test, songs, albums, artists, playlists, like];
}

class AdsCubit extends Cubit<AdsState> {
  /// convenience method
  static AdsCubit of(BuildContext context) =>
      BlocProvider.of<AdsCubit>(context);

  /// ads
  final BannerAd testBanner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3940256099942544/6300978111",
      listener: BannerAdListener(),
      request: AdRequest());

  final BannerAd songsBanner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-7519220681088057/6486612293",
      listener: BannerAdListener(),
      request: AdRequest());

  final BannerAd albumsBanner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-7519220681088057/5907742382",
      listener: BannerAdListener(),
      request: AdRequest());

  final BannerAd artistsBanner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-7519220681088057/4594660714",
      listener: BannerAdListener(),
      request: AdRequest());

  final BannerAd playlistsBanner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-7519220681088057/7608122278",
      listener: BannerAdListener(),
      request: AdRequest());

  AdsCubit() : super(AdsState(false, false, false, false, false, false)) {
    testBanner.load().then((value) => emit(state.copyWith(test: true)));
    songsBanner.load().then((value) => emit(state.copyWith(songs: true)));
    albumsBanner.load().then((value) => emit(state.copyWith(albums: true)));
    artistsBanner.load().then((value) => emit(state.copyWith(artists: true)));
    playlistsBanner
        .load()
        .then((value) => emit(state.copyWith(playlists: true)));

    // check app starts

    Hive.openBox("ads").then((box) {
      int starts = box.get("starts", defaultValue: 0);

      // show dialog after 5th start
      if (starts == 5) {
        emit(state.copyWith(like: true));
        emit(state.copyWith(like: false));
      }

      // increment on each start
      if (starts < 6) {
        box.put("starts", starts + 1);
      }

      // close box
      box.close();
    });
  }

  BannerAd getBanner(SelectedTab selectedTab) {
    // for test
    return testBanner;

    switch (selectedTab) {
      case SelectedTab.SONG:
        return songsBanner;
      case SelectedTab.ALBUM:
        return albumsBanner;
      case SelectedTab.ARTIST:
        return artistsBanner;
      case SelectedTab.PLAYLIST:
        return playlistsBanner;
    }
  }

  @override
  Future<void> close() async {
    songsBanner.dispose();
    albumsBanner.dispose();
    artistsBanner.dispose();
    playlistsBanner.dispose();
    testBanner.dispose();
    super.close();
  }
}
