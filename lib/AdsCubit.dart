import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AdsState extends Equatable {
  final bool like;

  AdsState(this.like);

  AdsState copyWith({bool? like}) => AdsState(like ?? this.like);

  @override
  List<Object?> get props => [like];
}

class AdsCubit extends Cubit<AdsState> {
  /// convenience method
  static AdsCubit of(BuildContext context) =>
      BlocProvider.of<AdsCubit>(context);

  AdsCubit() : super(AdsState(false)) {
    // check app starts

    Hive.openBox("ads").then((box) async {
      int starts = box.get("starts", defaultValue: 0);

      await Future.delayed(Duration(seconds: 3));

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
}
