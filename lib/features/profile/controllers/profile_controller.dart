import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/profile/providers/profile_providers.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final userId = ref.watch(
      authControllerProvider.select((value) => value.value?.session?.user.id),
    );
    if (userId == null) {
      throw const AppFailure(message: 'No hay una sesión activa.');
    }
    return ref.watch(profileRepositoryProvider).getCurrentProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading<UserProfile>();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getCurrentProfile(),
    );
  }
}
