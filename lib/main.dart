import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:peace/AdsCubit.dart';
import 'package:peace/PlayerScreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AppCubit.dart';

const int THUMBNAIL_COUNT = 74;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  var status = await Permission.storage.request();
  if (!status.isGranted) return;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppCubit>(
      create: (_) => AppCubit(),
      lazy: false,
      child: BlocProvider<MediaPlaybackCubit>(
        create: (_) => MediaPlaybackCubit(),
        lazy: false,
        child: BlocProvider(
          create: (_) => AdsCubit(),
          lazy: false,
          child: MaterialApp(
            theme: ThemeData(
                accentColor: Color(0xFF303030),
                scaffoldBackgroundColor: Color(0xFF222222),
                appBarTheme: AppBarTheme(backgroundColor: Color(0xFF222222)),
                iconTheme: IconThemeData(color: Colors.white),
                dialogBackgroundColor: Color(0xFF222222),
                dialogTheme: DialogTheme(
                    titleTextStyle:
                        TextStyle(color: Colors.white, fontSize: 20),
                    contentTextStyle: TextStyle(color: Colors.white)),
                sliderTheme: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: Colors.deepPurple,
                    inactiveTrackColor: Colors.white12,
                    rangeThumbShape: RoundRangeSliderThumbShape(
                        enabledThumbRadius: 0, disabledThumbRadius: 0),
                    thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 0, disabledThumbRadius: 0)),
                textTheme: GoogleFonts.robotoTextTheme(Theme.of(context)
                    .textTheme
                    .copyWith(
                        caption: TextStyle(color: Colors.white),
                        bodyText2: TextStyle(color: Colors.white),
                        headline5: TextStyle(color: Colors.white)))),
            title: 'Peace',
            home: PlayerScreen(),
          ),
        ),
      ),
    );
  }
}
