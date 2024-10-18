import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:rxdart/rxdart.dart';

class NearWidgetsController {
  final NearSocialApi nearSocialApi;

  NearWidgetsController({required this.nearSocialApi});

  final BehaviorSubject<NearWidgets> _streamController =
      BehaviorSubject.seeded(const NearWidgets());

  Stream<NearWidgets> get stream => _streamController.stream.distinct();
  NearWidgets get state => _streamController.value;

  Future<void> getNearWidgets() async {
    _streamController.add(state.copyWith(status: NearWidgetStatus.loading));
    try {
      final nearWidgets = await nearSocialApi.getWidgetsList();
      _streamController.add(
        NearWidgets(
          status: NearWidgetStatus.loaded,
          widgetList: nearWidgets
            ..sort(
              (a, b) {
                if (a.name.isEmpty && b.name.isNotEmpty) {
                  return 1;
                } else if (a.name.isNotEmpty && b.name.isEmpty) {
                  return -1;
                } else {
                  return b.blockHeight.compareTo(a.blockHeight);
                }
              },
            ),
        ),
      );
    } catch (e) {
      _streamController.add(state.copyWith(status: NearWidgetStatus.initial));
      rethrow;
    }
  }
}

enum NearWidgetStatus { initial, loading, loaded }

class NearWidgets extends Equatable {
  final NearWidgetStatus status;
  final List<NearWidgetInfo> widgetList;

  const NearWidgets({
    this.widgetList = const [],
    this.status = NearWidgetStatus.initial,
  });

  NearWidgets copyWith({
    NearWidgetStatus? status,
    List<NearWidgetInfo>? widgetList,
  }) =>
      NearWidgets(
        status: status ?? this.status,
        widgetList: widgetList ?? this.widgetList,
      );

  @override
  List<Object?> get props => [status, widgetList];

  @override
  bool? get stringify => true;
}
