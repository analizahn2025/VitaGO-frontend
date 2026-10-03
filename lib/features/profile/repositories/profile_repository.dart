import 'package:vitago_app/features/profile/models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getCurrentProfile();
}
