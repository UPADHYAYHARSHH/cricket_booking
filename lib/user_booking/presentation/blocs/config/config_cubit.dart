import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/services/remote_config_service.dart';

abstract class ConfigState {}

class ConfigInitial extends ConfigState {}

class ConfigLoaded extends ConfigState {
  final bool isMaintenanceMode;
  ConfigLoaded({required this.isMaintenanceMode});
}

class ConfigCubit extends Cubit<ConfigState> {
  final RemoteConfigService _remoteConfigService;
  StreamSubscription? _subscription;

  ConfigCubit(this._remoteConfigService) : super(ConfigInitial()) {
    _init();
  }

  void _init() {
    emit(ConfigLoaded(isMaintenanceMode: _remoteConfigService.isMaintenanceMode));

    _subscription = _remoteConfigService.maintenanceModeStream.listen((isMaintenance) {
      emit(ConfigLoaded(isMaintenanceMode: isMaintenance));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
