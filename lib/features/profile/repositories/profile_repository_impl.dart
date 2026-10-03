import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/profile/repositories/profile_repository.dart';
import 'package:vitago_app/features/profile/services/profile_api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._apiService);

  final ProfileApiService _apiService;

  @override
  Future<UserProfile> getCurrentProfile() => _apiService.getCurrentProfile();
}
