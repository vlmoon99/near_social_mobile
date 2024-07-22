import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/services/firebase/near_social_project/firestore_database.dart';
import 'package:rxdart/rxdart.dart';

class GlobalSettingsController extends Disposable {
  final BehaviorSubject<GlobalSettings> _streamController =
      BehaviorSubject.seeded(const GlobalSettings());

  Stream<GlobalSettings> get stream => _streamController.stream;
  GlobalSettings get state => _streamController.value;

  Future<void> loadGlobalSettings() async {
    _streamController
        .add(state.copyWith(loadStatus: GlobalSettingsLoadStatus.loading));
    final Map<String, dynamic> globalSettings =
        await FirebaseDatabaseService.getAllRecordsOfCollection(
            FirebaseDatabasePathKeys.globalSettingsDir);

    _streamController.add(
      state.copyWith(
        loadStatus: GlobalSettingsLoadStatus.loaded,
        allowKeyManagerFeature:
            globalSettings[FirebaseDatabasePathKeys.featuresSettingsPath]
                    ['allowKeyManagerFeature'] ??
                false,
      ),
    );
    log("Allow key manager feature: ${state.allowKeyManagerFeature}");
  }

  @override
  void dispose() {
    _streamController.close();
  }
}

enum GlobalSettingsLoadStatus { init, loading, loaded }

@immutable
class GlobalSettings {
  final bool allowKeyManagerFeature;
  final GlobalSettingsLoadStatus loadStatus;

  const GlobalSettings({
    this.loadStatus = GlobalSettingsLoadStatus.init,
    this.allowKeyManagerFeature = false,
  });

  GlobalSettings copyWith({
    GlobalSettingsLoadStatus? loadStatus,
    bool? allowKeyManagerFeature,
  }) {
    return GlobalSettings(
      loadStatus: loadStatus ?? this.loadStatus,
      allowKeyManagerFeature:
          allowKeyManagerFeature ?? this.allowKeyManagerFeature,
    );
  }
}
