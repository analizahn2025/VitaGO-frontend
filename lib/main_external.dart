import 'package:vitago_app/app/bootstrap.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';

void main() {
  bootstrapVitaGo(AppConfig.fromEnvironment(fixedMode: AppMode.external));
}
