import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/services/remote_config_service.dart';

abstract class ConfigState {}

class ConfigInitial extends ConfigState {}

class ConfigLoaded extends ConfigState {
  final bool isMaintenanceMode;
  final bool isUpdateRequired;
  final String updateUrl;
  ConfigLoaded({
    required this.isMaintenanceMode,
    required this.isUpdateRequired,
    required this.updateUrl,
  });
}

class ConfigCubit extends Cubit<ConfigState> {
  final RemoteConfigService _remoteConfigService;
  StreamSubscription? _subscription;

  ConfigCubit(this._remoteConfigService) : super(ConfigInitial()) {
    _init();
  }

  void _init() async {
    final isUpdate = await _remoteConfigService.isUpdateRequired();
    emit(ConfigLoaded(
      isMaintenanceMode: _remoteConfigService.isMaintenanceMode,
      isUpdateRequired: isUpdate,
      updateUrl: _remoteConfigService.updateUrl,
    ));

    _subscription = _remoteConfigService.maintenanceModeStream.listen((isMaintenance) async {
      final isUpdateRequired = await _remoteConfigService.isUpdateRequired();
      emit(ConfigLoaded(
        isMaintenanceMode: isMaintenance,
        isUpdateRequired: isUpdateRequired,
        updateUrl: _remoteConfigService.updateUrl,
      ));
    });
  }

  Future<void> refresh() async {
    await _remoteConfigService.fetchAndActivate();
    final isUpdate = await _remoteConfigService.isUpdateRequired();
    emit(ConfigLoaded(
      isMaintenanceMode: _remoteConfigService.isMaintenanceMode,
      isUpdateRequired: isUpdate,
      updateUrl: _remoteConfigService.updateUrl,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _remoteConfigService.dispose();
    return super.close();
  }
}
